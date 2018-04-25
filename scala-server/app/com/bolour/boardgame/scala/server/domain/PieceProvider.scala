/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import scala.util.{Success, Try}
import com.bolour.boardgame.scala.common.domain.Piece

/**
  * Factory for generating new pieces as pieces are consumed in plays.
  */
sealed abstract class PieceProvider {

  def take(): Try[(PieceProvider, Piece)]

  def takePieces(num: Int): Try[(PieceProvider, List[Piece])] = takePiecesAux(List(), num)

  def takePiecesAux(pieces: List[Piece], n: Int): Try[(PieceProvider, List[Piece])] = {
    if (n == 0)
      return Success((this, pieces))
    for {
      (provider1, piece) <- take()
      (provider2, pieces) <- provider1.takePiecesAux(piece +: pieces, n - 1)
    } yield (provider2, pieces)
  }

  def swapOne(piece: Piece): Try[(PieceProvider, Piece)] = {
    for {
      (provider1, resultPiece) <- this.take()
    } yield (provider1, resultPiece)
  }
}

/**
  * Cyclic piece generator - cycles through a given list of letters generating successive pieces.
  *
  * @param valueList The list of letters to cycle through.
  */
case class CyclicPieceProvider(valueList: String) extends PieceProvider {
  if (valueList == null || valueList.isEmpty)
    throw new IllegalArgumentException("empty cyclic generator value list")
  val cycleLength: Int = valueList.length
  var counter: BigInt = 0

  override def take(): Try[(PieceProvider, Piece)] = Try {
    val index: Int = (counter % cycleLength).toInt
    val value = valueList(index)
    val id = counter.toString
    counter = counter + 1
    (this, Piece(value, id))
  }
}

object CyclicPieceProvider {
  def apply() = new CyclicPieceProvider("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

/**
  * Random piece generator - generate pieces with random letters.
  */
case class RandomPieceProvider(randomizer: () => Char) extends PieceProvider {

  var counter: BigInt = 0

  def take(): Try[(RandomPieceProvider, Piece)] = {
    val letter = randomizer()
    val id = counter.toString
    val piece = Piece(letter, id)
    counter = counter + 1
    Try((this, piece))
  }
}

