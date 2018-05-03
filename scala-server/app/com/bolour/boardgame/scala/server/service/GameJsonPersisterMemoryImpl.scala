package com.bolour.boardgame.scala.server.service

import scala.util.Try
import com.bolour.util.scala.common.CommonUtil.ID

import scala.collection.mutable

/**
  * In-memory persister for the game application using JSON representations
  * objects to be persisted.
  */
class GameJsonPersisterMemoryImpl extends GameJsonPersister {

  var playersByName: mutable.Map[String, String] = mutable.Map[String, String]()
  var gamesById = mutable.Map[ID, String]()

  override def migrate() = Try {}

  override def clearPlayers() = Try { playersByName = mutable.Map.empty }

  override def clearGames() = Try { gamesById = mutable.Map.empty }

  override def savePlayer(playerId: ID, playerName: String, json: String) = Try {
    playersByName += ((playerName, json))
  }

  override def findPlayerByName(name: String) = Try {
    playersByName.get(name)
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
