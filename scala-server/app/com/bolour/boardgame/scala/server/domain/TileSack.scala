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

sealed abstract class TileSack {

  import TileSack.takeOneIfAvailable

  def isEmpty: Boolean
  def isFull: Boolean
  def length: Int
  def take(): Try[(TileSack, Piece)]
  def give(piece: Piece): Try[(TileSack)]

  def takeAvailableTiles(max: Int): Try[(TileSack, List[Piece])] = takeOneIfAvailable(this, List(), max)

  def swapOne(piece: Piece): Try[(TileSack, Piece)] = {
    for {
      (sack1, resultPiece) <- this.take()
      sack2 <- sack1.give(piece) // TODO. Should check for existence.
    } yield (sack2, resultPiece)
  }

  // TODO. Implement swapPieces.
  def swapPieces(swapped: List[Piece]): Try[(TileSack, List[Piece])] = ???
}

// TODO. Use default piece generators for dev test and production.
// Ideally should be configurable in teh application.conf.
object TileSack {

  def takeOneIfAvailable(sack: TileSack, pieces: List[Piece], n: Int): Try[(TileSack, List[Piece])] = {
    if (n == 0 || sack.isEmpty)
      return Success((sack, pieces))
    for {
      (sack1, piece) <- sack.take()
      (sack2, pieces) <- takeOneIfAvailable(sack1, piece +: pieces, n - 1)
    } yield (sack2, pieces)
  }

}

case class CyclicTileSack(valueList: String) extends TileSack {
  if (valueList == null || valueList.isEmpty)
    throw new IllegalArgumentException("empty cyclic generator value list")
  val cycleLength: Int = valueList.length
  var counter: BigInt = 0

  override def isEmpty: Boolean = false
  override def isFull: Boolean = false
  override def length: Int = Int.MaxValue

  override def take(): Try[(TileSack, Piece)] = Try {
    val index: Int = (counter % cycleLength).toInt
    val value = valueList(index)
    val id = counter.toString
    counter = counter + 1
    (this, Piece(value, id))
  }

  override def give(piece: Piece): Try[(TileSack)] = Success(this)
}

object CyclicTileSack {
  def apply() = new CyclicTileSack("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

case class RandomTileSack(initialContents: Vector[Piece], contents: Vector[Piece]) extends TileSack {

  val logger = LoggerFactory.getLogger(this.getClass)

  override def isEmpty: Boolean = contents.isEmpty
  def isFull: Boolean = contents.length == initialContents.length
  override def length: Int = contents.length

  def take(): Try[(RandomTileSack, Piece)] = Try {
    if (contents.isEmpty)
      throw new IllegalArgumentException(s"attempt to take a random piece from empty sack")
    val index = (Math.random() * contents.length).toInt
    val piece = contents(index)
    val rest = contents.patch(index, Nil, 1)
    (RandomTileSack(initialContents, rest), piece)
  }

  override def give(piece:Piece): Try[RandomTileSack] = Try {
    if (isFull)
      throw new IllegalStateException(s"cannot add to full tile stack - piece: ${piece}")
    // TODO. Check that piece belongs to initial contents.
    RandomTileSack(initialContents, piece +: contents)
  }

  override def swapPieces(swapped: List[Piece]): Try[(RandomTileSack, List[Piece])] = Try {
    val existing = swapped intersect contents
    if (existing.nonEmpty)
      throw new IllegalArgumentException(s"attempt to swap existing piece(s) - ${existing}")

    val nonExistent = swapped diff initialContents
    if (nonExistent.nonEmpty) // TODO. Use GameException.
      throw new IllegalArgumentException(s"attempt to swap non-existent piece(s) - ${nonExistent}")

    val n = swapped.length

    if (n >= contents.length)
      throw new IllegalArgumentException(s"attempt to swap more pieces (${n}) than exist in tile sack (${contents.length})")

    val (restContent, randomPieces) = BasicUtil.giveRandomElements((contents, Vector()), n)
    val replacedContent = restContent ++ swapped
    (RandomTileSack(initialContents, replacedContent), randomPieces.toList)
  }
}

object RandomTileSack {

  def apply(dimension: Int): RandomTileSack = {
    val pieces = mkInitialContents(dimension)
    RandomTileSack(pieces, pieces)
  }

  def apply(initialPieces: Vector[Piece]): RandomTileSack = {
    RandomTileSack(initialPieces, initialPieces)
  }

  /**
    * Put together the initial contents of a tile sack for any dimension.
    *
    * The letter frequencies for a 15x15 board are provided in Piece.frequencyMap.
    * The frequencies for a different dimension are computed by scaling the 15x15
    * frequencies based on board area.
    */
  def mkInitialContents(dimension: Int): Vector[Piece] = {
    val frequenciesFor15Board = Piece.frequencyMap

    val area15 = (15 * 15).toFloat
    val area = (dimension * dimension).toFloat
    val factor = area/area15

    /**
      * Scale the frequency of a letter making sure each letter
      * has at least one instance in the sack.
      */
    def repeats(frequencies: Map[Char, Int])(ch: Char): Int =
      Math.round(frequencies(ch) * factor).max(1)

    generatePieces(frequenciesFor15Board, repeats)
  }

  def generatePieces(baseFrequencies: Map[Char, Int], repetition: Map[Char, Int] => Char => Int) = {
    var id = -1
    val pieces = baseFrequencies.toList flatMap {
      case (ch, _) => (0 until repetition(baseFrequencies)(ch)).map { _ =>
        id += 1
        Piece(ch, id.toString)
      }
    }
    pieces.toVector
  }
}
