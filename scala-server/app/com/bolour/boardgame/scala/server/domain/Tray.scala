/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.server.domain.GameExceptions._
import com.bolour.boardgame.scala.common.domain.Piece

import scala.util.{Failure, Success, Try}

/**
  * Tray including the pieces available for play to a given player.
  * In our game, a tray is always full to its capacity (except in test situations).
  *
  * @param capacity The number of slots in the tray.
  * @param pieces The pieces in the tray.
  */
case class Tray(capacity: Int, pieces: Vector[Piece]) {

  /**
    * Replace a set of tray pieces.
    * TODO. Validate the parameters.
    */
  def replacePieces(removals: List[Piece], additions: List[Piece]): Tray = {
    val remainingPieces = pieces diff removals
    val updatedPieces = remainingPieces ++ additions
    Tray(capacity, updatedPieces)
  }

  def isFull: Boolean = pieces.length == capacity

  def addPiece(piece: Piece): Try[Tray] = {
    val found = pieces.find( _ == piece)
    if (found.nonEmpty)
      Failure(new IllegalArgumentException(s"piece already exists in tray"))
    if (isFull)
      Failure(new IllegalStateException(s"tray is full"))
    Success(Tray(capacity, piece +: pieces))
  }

  def removePiece(piece: Piece): Try[Tray] = {
    val i = pieces.indexOf(piece)
    if (i < 0)
      Failure(new MissingPieceException(piece.id))
    val updatedPieces = pieces.patch(i, Nil, 1)
    Success(Tray(capacity, updatedPieces))
  }

  def findPieceByLetter(letter: Char): Option[Piece] = pieces.find(_.value == letter)

  def letters: String = pieces.map(_.value).mkString
}

