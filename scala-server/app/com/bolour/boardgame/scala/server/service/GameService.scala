/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import com.bolour.util.BasicUtil.ID
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.Scorer.Score
import com.bolour.boardgame.scala.server.domain.{Game, GameState, Player}

import scala.util.Try

trait GameService {

  // TODO. Add parameter validation is common to all implementations.

  def migrate(): Try[Unit]

  def reset(): Try[Unit]

  def addPlayer(player: Player): Try[Unit]

  def startGame(
    gameParams: GameParams,
    gridPieces: List[GridPiece],
    initUserPieces: List[Piece],
    initMachinePieces: List[Piece],
    pointValues: List[List[Int]]
  ): Try[GameState]
  // ): Try[(GameState, Option[List[PlayPiece]])]

  def commitPlay(gameId: ID, playPieces: List[PlayPiece]): Try[(GameMiniState, List[Piece], List[Point])]

  def machinePlay(gameId: ID): Try[(GameMiniState, List[PlayPiece], List[Point])]

  def swapPiece(gameId: ID, piece: Piece): Try[(GameMiniState, Piece)]

  def endGame(gameId: ID): Try[GameSummary]

  def findGameById(gameId: ID): Try[Option[Game]]

  def timeoutLongRunningGames(): Try[Unit]

}

object GameService {
  val serviceConfigPrefix = "service"
  def confPath(pathInService: String) =  s"${serviceConfigPrefix}.${pathInService}"

  val maxActiveGamesConfigPath = confPath("maxActiveGames")
  val maxGameMinutesConfigPath = confPath("maxGameMinutes")
  val languageCodesConfigPath = confPath("languageCodes")

}
