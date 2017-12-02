/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import com.bolour.boardgame.scala.common.domain.PieceGeneratorType._

trait PieceGenerator {
  def next(): Piece
}

// TODO. Use default piece generators for dev test and production.
// Ideally should be configurable in teh application.conf.
object PieceGenerator {
  class CyclicPieceGenerator(val valueList: String) extends PieceGenerator {
    if (valueList == null || valueList.isEmpty)
      throw new IllegalArgumentException("empty cyclic generator value list")
    val cycleLength: Int = valueList.length
    var counter: BigInt = 0
    override def next(): Piece = {
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

  class RandomPieceGenerator extends PieceGenerator {
    var counter: BigInt = 0
    override def next(): Piece = {
      val id = counter.toString
      counter = counter + 1
      Piece.randomPiece(id)
    }
  }

  object RandomPieceGenerator {
    def apply(): RandomPieceGenerator = new RandomPieceGenerator()
  }

  def apply(pieceGeneratorType: PieceGeneratorType): PieceGenerator = {
    pieceGeneratorType match {
      case `cyclic` => CyclicPieceGenerator()
      case `random` => RandomPieceGenerator()
    }
  }
}
