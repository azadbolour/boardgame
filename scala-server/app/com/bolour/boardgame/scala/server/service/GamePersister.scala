/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import com.bolour.boardgame.scala.server.domain.{Game, Player}
import com.bolour.util.scala.common.CommonUtil.ID

import scala.util.Try

/**
  * High-level persister interface for game application objects.
  */
trait GamePersister {

  def migrate(): Try[Unit]

  def clearAllData(): Try[Unit] = {
    for {
      _ <- clearGames()
      _ <- clearPlayers()
    } yield ()
  }

  def clearGames(): Try[Unit]
  def clearPlayers(): Try[Unit]

  def savePlayer(player: Player): Try[Unit]
  def findPlayerByUserId(userId: String): Try[Option[Player]]

  def saveGame(game: GameData): Try[Unit]
  def findGameById(gameId: ID): Try[Option[GameData]]
  def deleteGame(gameId: ID): Try[Unit]

}
