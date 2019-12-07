package com.bolour.boardgame.scala.server.service

import scala.util.Try
import com.bolour.util.scala.common.CommonUtil.{Email, ID}

import scala.collection.mutable

/**
  * In-memory persister for the game application using JSON representations
  * objects to be persisted.
  */
class GameJsonPersisterMemoryImpl extends GameJsonPersister {

  var playersByUserId: mutable.Map[String, String] = mutable.Map[String, String]()
  var gamesById = mutable.Map[ID, String]()

  override def migrate() = Try {}

  override def clearPlayers() = Try { playersByUserId = mutable.Map.empty }

  override def clearGames() = Try { gamesById = mutable.Map.empty }

  override def savePlayer(playerId: ID, userId: String, playerName: String, email: Email, json: String) = Try {
    playersByUserId += ((userId, json))
  }

  override def findPlayerByUserId(userId: String) = Try {
    playersByUserId.get(userId)
  }

  override def saveGame(gameId: ID, playerId: ID, json: String) = Try {
    gamesById += ((gameId, json))
    // TODO. save playerId to make possible retrieval of games of player.
  }

  override def findGameById(gameId: ID) = Try {
    gamesById.get(gameId)
  }

  override def deleteGame(gameId: ID) = Try {
    gamesById.remove(gameId)
  }
}
