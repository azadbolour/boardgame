/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import com.bolour.boardgame.scala.server.domain.GameExceptions._

import scala.util.{Failure, Success, Try}

// TODO. State whether tray should always be full to capacity.


case class Tray(capacity: Int, pieces: Vector[Piece]) {

  /** Assume for now that caller is using correct parameters. */
  def replacePieces(removals: List[Piece], additions: List[Piece]): Tray = {
    val remainingPieces = pieces diff removals
    val updatedPieces = remainingPieces ++ additions
    Tray(capacity, updatedPieces)
  }

  def swapPiece(piece: Piece)(implicit pieceGenerator: TileSack): Try [(Piece, Tray)] = {
    val maybePiece = pieces.find(_ == piece)
    if (maybePiece.isEmpty)
      Failure(new MissingPieceException(piece.id))
    val newPiece = pieceGenerator.take()
    val newTray = this.copy(pieces = pieces.filter(_ != piece) :+ newPiece)
    Success((newPiece, newTray))
  }

  def findPieceByLetter(letter: Char): Option[Piece] = pieces.find(_.value == letter)

  def letters: String = pieces.map(_.value).mkString
}

