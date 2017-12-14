/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import com.bolour.boardgame.scala.common.domain.PieceGeneratorType._

trait TileSack {
  def take(): Piece

  def taken(n: Int): List[Piece] = {
    (0 until n).toList.map { i => take() }
  }

  def swap(pieces: List[Piece]): List[Piece] = {
    taken(pieces.length)
  }
}

// TODO. Use default piece generators for dev test and production.
// Ideally should be configurable in teh application.conf.
object TileSack {
  class CyclicPieceGenerator(val valueList: String) extends TileSack {
    if (valueList == null || valueList.isEmpty)
      throw new IllegalArgumentException("empty cyclic generator value list")
    val cycleLength: Int = valueList.length
    var counter: BigInt = 0

    override def take(): Piece = {
      val index: Int = (counter % cycleLength).toInt
      val value = valueList(index)
      val id = counter.toString
      counter = counter + 1
      Piece(value, id)
    }
  }

  object CyclicPieceGenerator {
    def apply() = new CyclicPieceGenerator("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  }

  class RandomPieceGenerator extends TileSack {
    var counter: BigInt = 0

    override def take(): Piece = {
      val id = counter.toString
      counter = counter + 1
      Piece.randomPiece(id)
    }
  }

  object RandomPieceGenerator {
    def apply(): RandomPieceGenerator = new RandomPieceGenerator()
  }

  def apply(pieceGeneratorType: PieceGeneratorType): TileSack = {
    pieceGeneratorType match {
      case Cyclic => CyclicPieceGenerator()
      case Random => RandomPieceGenerator()
    }
  }

}
