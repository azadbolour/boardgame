package com.bolour.boardgame.scala.server.service

import spray.json._
import com.bolour.boardgame.scala.server.domain.{Game, Player}
import com.bolour.util.scala.common.CommonUtil.ID
import com.bolour.boardgame.scala.server.domain.json.CaseClassFormats._
import com.bolour.boardgame.scala.server.service.json.CaseClassFormats._
import com.bolour.util.scala.common.VersionStamped

import scala.util.{Failure, Success, Try}

/**
  * Implementation of the hig-level game persister interface using a JSON persister.
  * Converts objects to their JSON representations and calls lower-level JSON
  * persister to persist them.
  *
  * @param jsonPersister The specific lower-level JSON persister to use.
  * @param version The server version - in case JSON representations change over time.
  */
class GamePersisterJsonImpl(jsonPersister: GameJsonPersister, version: Int) extends GamePersister {

  override def migrate() = jsonPersister.migrate()

  override def clearGames() = jsonPersister.clearGames()

  override def clearPlayers() = jsonPersister.clearPlayers()

  override def savePlayer(player: Player) = {
    val versionedPlayer = VersionStamped[Player](version, player)
    val json = versionedPlayer.toJson.prettyPrint
    jsonPersister.savePlayer(player.id, player.name, json)
  }

  override def findPlayerByName(name: String) = {
    for {
      ojson <- jsonPersister.findPlayerByName(name)
      oplayer = ojson map { json =>
        val jsonAst = json.parseJson
        val versionedPlayer = jsonAst.convertTo[VersionStamped[Player]]
        versionedPlayer.data
      }
    } yield oplayer
  }

  override def saveGame(gameData: GameData): Try[Unit] = {
    val versionedGameData = VersionStamped[GameData](version, gameData)
    val gameId = gameData.base.id
    val playerId = gameData.base.playerId
    val json = versionedGameData.toJson.prettyPrint
    // TODO. Game should expose id itself.
    jsonPersister.saveGame(gameId, playerId, json)
  }

  override def findGameById(gameId: ID) = {
    for {
      ojson <- jsonPersister.findGameById(gameId)
      odata = ojson map { json =>
        val jsonAst = json.parseJson
        val versionedData = jsonAst.convertTo[VersionStamped[GameData]]
        versionedData.data
      }
    } yield odata
  }

  override def deleteGame(gameId: ID) = jsonPersister.deleteGame(gameId)

}
