package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{Piece, PlayPiece}
import com.bolour.boardgame.scala.common.domain.PlayerType._
import com.bolour.plane.scala.domain.Point

/**
  * Representation of a play in the game - a word play or a swap play.
  * Used to store plays as JSON strings in the database.
  */
sealed abstract class Play(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int])

/**
  * Construct by using mkWordPlay to prevent error in play type.
  * Forced to add redundant tag to easily do json.
  */
case class WordPlay(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int],
  playPieces: List[PlayPiece], replacementPieces: List[Piece], deadPoints: List[Point]) extends Play(playType, playNumber, playerType, scores)

/**
  * Construct by using mkSwapPlay to prevent error in play type.
  * Forced to add redundant tag to easily do json.
  */
case class SwapPlay(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int],
  swappedPiece: Piece, newPiece: Piece) extends Play(playType, playNumber, playerType, scores)

object Play {
  def mkWordPlay(playNumber: Int, playerType: PlayerType, scores: List[Int],
    playPieces: List[PlayPiece], replacementPieces: List[Piece], deadPoints: List[Point]): Play =
    WordPlay(WordPlayType, playNumber, playerType, scores, playPieces, replacementPieces, deadPoints)

  def mkSwapPlay(playNumber: Int, playerType: PlayerType, scores: List[Int],
    swappedPiece: Piece, newPiece: Piece): Play =
    SwapPlay(SwapPlayType, playNumber, playerType, scores, swappedPiece, newPiece)
}