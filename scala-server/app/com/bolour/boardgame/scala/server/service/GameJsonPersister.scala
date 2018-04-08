/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import com.bolour.util.scala.common.CommonUtil.ID

import scala.util.Try

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

  def saveJsonVersionedPlayer(playerId: ID, playerName: String, json: String): Try[Unit]
  def findJsonVersionedPlayerByName(name: String): Try[Option[String]]

  def saveJsonVersionedGameTransitions(gameId: ID, playerId: ID, json: String): Try[Unit]
  def findJsonVersionedGameTransitionsById(gameId: ID): Try[Option[String]]

}
