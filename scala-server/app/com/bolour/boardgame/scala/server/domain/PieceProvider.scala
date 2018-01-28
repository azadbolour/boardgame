/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import com.bolour.util.BasicUtil
import org.slf4j.LoggerFactory

import scala.util.{Success, Try}

sealed abstract class PieceProvider {

  import PieceProvider.takeAvailableTilesToList

  def isEmpty: Boolean
  def isFull: Boolean
  def length: Int
  def take(): Try[(PieceProvider, Piece)]
  def give(piece: Piece): Try[(PieceProvider)]

  def takeAvailableTiles(max: Int): Try[(PieceProvider, List[Piece])] = takeAvailableTilesToList(this, List(), max)

  def swapOne(piece: Piece): Try[(PieceProvider, Piece)] = {
    for {
      (provider1, resultPiece) <- this.take()
      provider2 <- provider1.give(piece) // TODO. Should check for existence.
    } yield (provider2, resultPiece)
  }

  // TODO. Implement swapPieces.
  def swapPieces(swapped: List[Piece]): Try[(PieceProvider, List[Piece])] = ???
}

// TODO. Use default piece generators for dev test and production.
// Ideally should be configurable in the application.conf.
object PieceProvider {

  def takeAvailableTilesToList(provider: PieceProvider, pieces: List[Piece], n: Int): Try[(PieceProvider, List[Piece])] = {
    if (n == 0 || provider.isEmpty)
      return Success((provider, pieces))
    for {
      (provider1, piece) <- provider.take() // TODO. Make sure it does not fail - check provider length.
      (provider2, pieces) <- takeAvailableTilesToList(provider1, piece +: pieces, n - 1)
    } yield (provider2, pieces)
  }

}

case class CyclicPieceProvider(valueList: String) extends PieceProvider {
  if (valueList == null || valueList.isEmpty)
    throw new IllegalArgumentException("empty cyclic generator value list")
  val cycleLength: Int = valueList.length
  var counter: BigInt = 0

  override def isEmpty: Boolean = false
  override def isFull: Boolean = false
  override def length: Int = Int.MaxValue

  override def take(): Try[(PieceProvider, Piece)] = Try {
    val index: Int = (counter % cycleLength).toInt
    val value = valueList(index)
    val id = counter.toString
    counter = counter + 1
    (this, Piece(value, id))
  }

  override def give(piece: Piece): Try[(PieceProvider)] = Success(this)
}

object CyclicPieceProvider {
  def apply() = new CyclicPieceProvider("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

case class RandomPieceProvider(initialContents: Vector[Piece], contents: Vector[Piece]) extends PieceProvider {

  val logger = LoggerFactory.getLogger(this.getClass)

  override def isEmpty: Boolean = contents.isEmpty
  def isFull: Boolean = contents.length == initialContents.length
  override def length: Int = contents.length

  def take(): Try[(RandomPieceProvider, Piece)] = Try {
    if (contents.isEmpty)
      throw new IllegalArgumentException(s"attempt to take a random piece from empty provider")
    val index = (Math.random() * contents.length).toInt
    val piece = contents(index)
    val rest = contents.patch(index, Nil, 1)
    (RandomPieceProvider(initialContents, rest), piece)
  }

  override def give(piece:Piece): Try[RandomPieceProvider] = Try {
    if (isFull)
      throw new IllegalStateException(s"cannot add to full tile stack - piece: ${piece}")
    // TODO. Check that piece belongs to initial contents.
    RandomPieceProvider(initialContents, piece +: contents)
  }

  override def swapPieces(swapped: List[Piece]): Try[(RandomPieceProvider, List[Piece])] = Try {
    val existing = swapped intersect contents
    if (existing.nonEmpty)
      throw new IllegalArgumentException(s"attempt to swap existing piece(s) - ${existing}")

    val nonExistent = swapped diff initialContents
    if (nonExistent.nonEmpty) // TODO. Use GameException.
      throw new IllegalArgumentException(s"attempt to swap non-existent piece(s) - ${nonExistent}")

    val n = swapped.length

    if (n >= contents.length)
      throw new IllegalArgumentException(s"attempt to swap more pieces (${n}) than exist in tile provider (${contents.length})")

    val (restContent, randomPieces) = BasicUtil.giveRandomElements((contents, Vector()), n)
    val replacedContent = restContent ++ swapped
    (RandomPieceProvider(initialContents, replacedContent), randomPieces.toList)
  }
}

object RandomPieceProvider {

  def apply(dimension: Int): RandomPieceProvider = {
    val pieces = mkInitialContents(dimension)
    RandomPieceProvider(pieces, pieces)
  }

  def apply(initialPieces: Vector[Piece]): RandomPieceProvider = {
    RandomPieceProvider(initialPieces, initialPieces)
  }

  /**
    * Put together the initial contents of a piece provider for any dimension.
    */
  def mkInitialContents(dimension: Int): Vector[Piece] = {
    val roughNumPieces = (dimension * dimension * 2)/3 // 2/3 is more than enough.
    val (letterFrequencies, total) = Piece.normalizedFrequencies(roughNumPieces)
    val contentLetters = letterFrequencies.toList flatMap {case (ch, freq) => List.fill(freq)(ch)}
    val ids = (0 until total) map { _.toString }
    val lettersAndIds = contentLetters zip ids
    val pieces = lettersAndIds map {case (ch, id) => Piece(ch, id)}
    pieces.toVector
  }

}
