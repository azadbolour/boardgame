/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import com.bolour.util.scala.common.util.CommonUtil
import org.slf4j.LoggerFactory

import scala.util.{Success, Try}

sealed abstract class PieceProvider {

  import PieceProvider.takeAvailableTilesToList

  def isEmpty: Boolean
  def isFull: Boolean
  def take(): Try[(PieceProvider, Piece)]
  def give(piece: Piece): Try[(PieceProvider)]

  def takeAvailableTiles(max: Int): Try[(PieceProvider, List[Piece])] = takeAvailableTilesToList(this, List(), max)

  def swapOne(piece: Piece): Try[(PieceProvider, Piece)] = {
    for {
      (provider1, resultPiece) <- this.take()
      provider2 <- provider1.give(piece) // TODO. Should check for existence.
    } yield (provider2, resultPiece)
  }
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

case class RandomPieceProvider() extends PieceProvider {

  val logger = LoggerFactory.getLogger(this.getClass)
  var counter: BigInt = 0

  override def isEmpty: Boolean = false
  def isFull: Boolean = false

  def take(): Try[(RandomPieceProvider, Piece)] = {
    val piece = Piece.randomPiece(counter.toString())
    counter = counter + 1
    Try((this, piece))
  }

  override def give(piece:Piece): Try[RandomPieceProvider] = Try {
    this
  }
}

