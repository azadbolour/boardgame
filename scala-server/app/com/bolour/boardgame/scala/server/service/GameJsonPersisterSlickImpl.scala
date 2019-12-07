/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import org.slf4j.LoggerFactory

import scala.concurrent.Await
import scala.concurrent.duration._
import com.typesafe.config.Config
import slick.jdbc.JdbcBackend.Database
import slick.jdbc.JdbcProfile
import com.bolour.util.scala.common.CommonUtil.{Email, ID}
import com.bolour.util.scala.server.SlickUtil.{configuredDbAndProfile, tableNames}

import scala.util.Try

/**
  * Implementation of JSON persister using Slick.
  */
class GameJsonPersisterSlickImpl(val profile: JdbcProfile, db: Database) extends GameJsonPersister {

  import profile.api._

  val logger = LoggerFactory.getLogger(this.getClass)

  val playerTableName = "player"
  val gameTableName = "game"

  // Use large timeout to avoid internal error on overloaded machine.
  val timeout = 5.seconds

  def tableMap = Map(playerTableName -> playerRows, gameTableName -> gameRows)
  def allTableNames = tableMap.keySet.toList

  case class PlayerRow(id: ID, userId: String, name: String, email: String, json: String)

  class PlayerTable(tag: Tag) extends Table[PlayerRow](tag, playerTableName) {
    def id = column[ID]("id", O.PrimaryKey)
    def userId = column[String]("user-id")
    def name = column[String]("name")
    def email = column[String]("email")
    def json = column[String]("json")

    def * = (id, userId, name, email, json).mapTo[PlayerRow]
  }

  def playerRows = TableQuery[PlayerTable]

  case class GameRow(id: ID, playerId: ID, json: String)

  class GameTable(tag: Tag) extends Table[GameRow](tag, gameTableName) {
    def id = column[ID]("id", O.PrimaryKey)
    def playerId = column[ID]("player-id")
    def json = column[String]("json")

    def * = (id, playerId, json).mapTo[GameRow]
  }

  def gameRows = TableQuery[GameTable]

  override def migrate() = Try {
    val existingTableNames = tableNames(db)
    val neededTableNames = allTableNames diff existingTableNames
    val creates = neededTableNames map {name => tableMap(name).schema.create}
    val future = db.run(DBIO.seq(creates:_*))
    Await.result(future, timeout)
  }

  override def clearPlayers() = Try {
    playerRows.delete
  }

  override def clearGames() = Try {
    gameRows.delete
  }

  // TODO. Best practices for value class (Email) as column type of Slick row?
  // For now just convert explicitly.
  override def savePlayer(playerId: ID, userId: String, playerName: String, email: Email, json: String) = Try {
    val playerRow = PlayerRow(playerId, userId, playerName, email.email, json)
    val save = playerRows.insertOrUpdate(playerRow)
    val future = db.run(save)
    val numRows = Await.result(future, timeout)
    logger.debug(s"added ${numRows} player(s)")
  }

  override def findPlayerByUserId(userId: String) = Try {
    val query = playerRows.filter {_.userId === userId }
    val future = db.run(query.result)
    val rows = Await.result(future, timeout)
    rows.headOption map { _.json }
  }

  override def saveGame(gameId: ID, playerId: ID, json: String) = Try {
    val gameRow = GameRow(gameId, playerId, json)
    val save = gameRows.insertOrUpdate(gameRow)
    val future = db.run(save)
    val numRows = Await.result(future, timeout)
    logger.debug(s"added ${numRows} game(s)")
  }

  override def findGameById(gameId: ID) = Try {
    val query = gameRows.filter {_.id === gameId }
    val future = db.run(query.result)
    val rows = Await.result(future, timeout)
    rows.headOption map { _.json }
  }

  override def deleteGame(gameId: ID) = Try {
    val query = gameRows.filter {_.id === gameId }
    val future = db.run(query.delete)
    Await.result(future, timeout)
  }
}

object GameJsonPersisterSlickImpl {

  val dbConfigPrefix = "service.db"
  def confPath(pathInDb: String) =  s"${dbConfigPrefix}.${pathInDb}"

  def apply(dbName: String, config: Config): GameJsonPersisterSlickImpl = {
    val dbConfigPath = confPath(dbName)
    val (myDb, myProfile) = configuredDbAndProfile(dbConfigPath)
    new GameJsonPersisterSlickImpl(myProfile, myDb)
  }
}