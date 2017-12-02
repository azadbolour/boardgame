/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import com.bolour.util.BasicUtil.ID
import com.bolour.boardgame.scala.common.domain._
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
    initMachinePieces: List[Piece]
  ): Try[GameState]
  // ): Try[(GameState, Option[List[PlayPiece]])]

  def commitPlay(gameId: ID, playPieces: List[PlayPiece]): Try[List[Piece]]

  def machinePlay(gameId: ID): Try[List[PlayPiece]]

  def swapPiece(gameId: ID, piece: Piece): Try[Piece]

  def endGame(gameId: ID): Try[Unit]

  def findGameById(gameId: ID): Try[Option[Game]]

}

object GameService {
  val serviceConfigPrefix = "service"
  def confPath(pathInService: String) =  s"${serviceConfigPrefix}.${pathInService}"

  val maxActiveGamesConfigPath = confPath("maxActiveGames")
  val languageCodesConfigPath = confPath("languageCodes")

}
