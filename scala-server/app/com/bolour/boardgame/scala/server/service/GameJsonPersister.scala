/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import com.bolour.util.scala.common.CommonUtil.ID

import scala.util.Try

/**
  * Persister of games and players using JSON representations.
  */
trait GameJsonPersister {

  def migrate(): Try[Unit]

  def clearAllData(): Try[Unit] = {
    for {
      _ <- clearGames()
      _ <- clearPlayers()
    } yield ()
  }

  def clearPlayers(): Try[Unit]
  def clearGames(): Try[Unit]

  def savePlayer(playerId: ID, playerName: String, json: String): Try[Unit]
  def findPlayerByName(name: String): Try[Option[String]]

  def saveGame(gameId: ID, playerId: ID, json: String): Try[Unit]
  def findGameById(gameId: ID): Try[Option[String]]
  def deleteGame(gameId: ID): Try[Unit]

}
