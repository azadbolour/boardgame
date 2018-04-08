package com.bolour.boardgame.scala.server.service

import spray.json._
import com.bolour.boardgame.scala.server.domain.{Game, GameTransitions, Player}
import com.bolour.util.scala.common.CommonUtil.ID
import com.bolour.boardgame.scala.server.domain.json.CaseClassFormats._
import com.bolour.util.scala.common.VersionStamped

import scala.util.{Failure, Success}

class GamePersisterJsonImpl(jsonPersister: GameJsonPersister, version: Int) extends GamePersister {

  override def migrate() = jsonPersister.migrate()

  override def clearGames() = jsonPersister.clearGames()

  override def clearPlayers() = jsonPersister.clearPlayers()

  override def savePlayer(player: Player) = {
    val versionedPlayer = VersionStamped[Player](version, player)
    val json = versionedPlayer.toJson.prettyPrint
    jsonPersister.saveJsonVersionedPlayer(player.id, player.name, json)
  }

  override def findPlayerByName(name: String) = {
    for {
      ojson <- jsonPersister.findJsonVersionedPlayerByName(name)
      oplayer = ojson map { json =>
        val jsonAst = json.parseJson
        val versionedPlayer = jsonAst.convertTo[VersionStamped[Player]]
        versionedPlayer.data
      }
    } yield oplayer
  }

  override def saveGame(game: Game) = {
    val versionedGameTransitions = VersionStamped[GameTransitions](version, game.transitions)
    val gameId = game.gameBase.id
    val playerId = game.gameBase.playerId
    val json = versionedGameTransitions.toJson.prettyPrint
    // TODO. Game should expose id itself.
    jsonPersister.saveJsonVersionedGameTransitions(gameId, playerId, json)
  }

  override def findGameById(gameId: ID) = {
    for {
      ojson <- jsonPersister.findJsonVersionedGameTransitionsById(gameId)
      otransitions = ojson map { json =>
        val jsonAst = json.parseJson
        val versionedTransitions = jsonAst.convertTo[VersionStamped[GameTransitions]]
        versionedTransitions.data
      }
      ogame <- otransitions match {
        case None => Success(None)
        case Some(transitions) =>
          Game.fromTransitions(transitions) match {
            case Failure(ex) => Failure(ex)
            case Success(game) => Success(Some(game))
          }
      }
    } yield ogame
  }

  override def deleteGame(gameId: ID) = jsonPersister.deleteVersionedGameTransitions(gameId)

}
