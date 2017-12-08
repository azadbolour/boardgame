/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.PlayerType._

import scala.util.{Failure, Success, Try}

case class GameState(
  game: Game,
  board: Board,
  trays: List[Tray],
  playNumber: Int,
  playTurn: PlayerType,
  scores: List[Int]
) {
  def addPlay(playerType: PlayerType, playPieces: List[PlayPiece]): Try[(GameState, List[Piece])] = {
    for {
      _ <- validatePlay(playPieces)
      movedGridPieces = playPieces filter { _.moved } map { _.gridPiece }
      score = computePlayScore(playPieces)
      added <- addGoodPlay(playerType, movedGridPieces, score)
    } yield added
  }

  def tray(playerType: PlayerType): Tray = trays(playerIndex(playerType))

  // TODO. Compute score.
  private def computePlayScore(playPieces: List[PlayPiece]): Int = game.scorer.scorePlay(playPieces)

  private def addGoodPlay(playerType: PlayerType, gridPieces: List[GridPiece], score: Int): Try[(GameState, List[Piece])] = {
    val newBoard = board.addPieces(gridPieces)
    val usedPieces = gridPieces map { _.value }
    val ind = playerIndex(playerType)
    val newPieces = game.mkPieces(usedPieces.length)
    val newTrays = trays.updated(ind, trays(ind).replacePieces(usedPieces, newPieces))
    val newScores = scores.updated(ind, scores(ind) + score)
    val nextType = nextPlayerType(playerType)
    val newState = GameState(game, newBoard, newTrays, playNumber + 1, nextType, newScores)
    Success((newState, newPieces))
  }

  // TODO validate play.
  // TODO. Check anchored on all except the first play.
  private def validatePlay(playPieces: List[PlayPiece]): Try[Unit] = Success(())
}

object GameState {
  def apply(game: Game, params: GameParams, gridPieces: List[GridPiece], initUserPieces: List[Piece], initMachinePieces: List[Piece]): GameState = {
    val board = Board(params.dimension, gridPieces)
    val userTray = mkTray(params.trayCapacity, initUserPieces, game.pieceGenerator)
    val machineTray = mkTray(params.trayCapacity, initMachinePieces, game.pieceGenerator)
    GameState(game, board, List(userTray, machineTray), 0, UserPlayer, List(0, 0))
  }

  def mkTray(capacity: Int, initPieces: List[Piece], pieceGen: PieceGenerator): Tray = {
    val pieces =
      if (initPieces.length >= capacity)
        initPieces.take(capacity)
      else {
        val num = capacity - initPieces.length
        val restPieces = List.fill(num) {
          pieceGen.next
        }
        initPieces ++ restPieces
      }
    Tray(capacity, pieces.toVector)
  }

}
