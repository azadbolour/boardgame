package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{Piece, PlayPiece}
import com.bolour.boardgame.scala.common.domain.PlayerType._

sealed abstract class Play(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int])

/**
  * Construct by using mkWordPlay to prevent error in play type.
  * Forced to add redundant tag to easily do json.
  */
case class WordPlay(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int],
  playPieces: List[PlayPiece], replacementPieces: List[Piece]) extends Play(playType, playNumber, playerType, scores)

/**
  * Construct by using mkSwapPlay to prevent error in play type.
  * Forced to add redundant tag to easily do json.
  */
case class SwapPlay(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int],
  swappedPiece: Piece, newPiece: Piece) extends Play(playType, playNumber, playerType, scores)

object Play {
  def mkWordPlay(playNumber: Int, playerType: PlayerType, scores: List[Int],
    playPieces: List[PlayPiece], replacementPieces: List[Piece]): Play =
    WordPlay(WordPlayType, playNumber, playerType, scores, playPieces, replacementPieces)

  def mkSwapPlay(playNumber: Int, playerType: PlayerType, scores: List[Int],
    swappedPiece: Piece, newPiece: Piece): Play =
    SwapPlay(SwapPlayType, playNumber, playerType, scores, swappedPiece, newPiece)
}