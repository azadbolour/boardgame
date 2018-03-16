/*
 * Copyright 2017-2018 Azad Bolour
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

  def isEmpty: Boolean = pieces.isEmpty

  def isFull: Boolean = pieces.length == capacity

  def sumLetterWorths: Int = (pieces map { _.worth }).sum

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

