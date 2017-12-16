/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece

import scala.util.{Success, Try}

trait TileSack {

  import TileSack.takeAdd

  def isEmpty: Boolean
  def isFull: Boolean
  def take(): Try[(TileSack, Piece)]
  def give(piece: Piece): Try[(TileSack)]

  def takeN(n: Int): Try[(TileSack, List[Piece])] = takeAdd(this, List(), n)

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

  def takeAdd(sack: TileSack, pieces: List[Piece], n: Int): Try[(TileSack, List[Piece])] = {
    if (n == 0)
      return Success((sack, pieces))
    for {
      (sack1, piece) <- sack.take()
      (sack2, pieces) <- takeAdd(sack1, piece +: pieces, n - 1)
    } yield (sack2, pieces)
  }


  class CyclicTileSack(val valueList: String) extends TileSack {
    if (valueList == null || valueList.isEmpty)
      throw new IllegalArgumentException("empty cyclic generator value list")
    val cycleLength: Int = valueList.length
    var counter: BigInt = 0

    override def isEmpty: Boolean = false
    override def isFull: Boolean = false

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

}
