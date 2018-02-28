/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import com.bolour.util.scala.common.util.CommonUtil.ID
import com.bolour.boardgame.scala.common.domain.PlayPiece
import com.bolour.boardgame.scala.server.domain.{Game, GameState, PieceProvider, Player}

import scala.util.Try

trait GameDao {

  def createNonExistentTables(): Try[Unit]

  def cleanupDb(): Try[Unit] = for {
    _ <- deleteAllPlays()
    _ <- deleteAllGames()
    _ <- deleteAllPlayers()
  } yield ()

  def deleteAllPlays(): Try[Unit]
  def deleteAllGames(): Try[Unit]
  def deleteAllPlayers(): Try[Unit]

  def addPlayer(player: Player): Try[Unit]
  def addGame(game: Game): Try[Unit]
  def endGame(id: String): Try[Unit]
  def addGameState(gameState: GameState): Try[Unit]
  def addPlay(gameId: ID, playPieces: List[PlayPiece]): Try[Unit]

  def findPlayerByName(name: String): Try[Option[Player]]
  def findGameById(id: ID): Try[Option[Game]]

}
