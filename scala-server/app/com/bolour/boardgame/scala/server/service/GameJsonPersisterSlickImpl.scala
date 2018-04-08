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

import com.bolour.util.scala.common.CommonUtil.ID
import com.bolour.util.scala.server.SlickUtil.{configuredDbAndProfile, tableNames}

import scala.util.Try

class GameJsonPersisterSlickImpl(val profile: JdbcProfile, db: Database) extends GameJsonPersister {

  import profile.api._
  import GameJsonPersisterSlickImpl._

  val logger = LoggerFactory.getLogger(this.getClass)

  val playerTableName = "player"
  val gameTableName = "game"

  // Use large timeout to avoid internal error on overloaded machine.
  val timeout = 5.seconds

  def tableMap = Map(playerTableName -> playerRows, gameTableName -> gameRows)
  def allTableNames = tableMap.keySet.toList

  case class PlayerRow(id: ID, name: String, json: String)

  class PlayerTable(tag: Tag) extends Table[PlayerRow](tag, playerTableName) {
    def id = column[ID]("id", O.PrimaryKey)
    def name = column[String]("name")
    def json = column[String]("json")

    def * = (id, name, json).mapTo[PlayerRow]
  }

  def playerRows = TableQuery[PlayerTable]
  // def fromPlayerRow(row: PlayerRow): Player = Player(row.id, row.name)

  case class GameRow(id: ID, json: String)

  class GameTable(tag: Tag) extends Table[GameRow](tag, gameTableName) {
    def id = column[ID]("id", O.PrimaryKey)
    def json = column[String]("json")

    def * = (id, json).mapTo[GameRow]
  }

  def gameRows = TableQuery[GameTable]
  // def toGameRow(id: ID, json: String): GameRow = GameRow(id, json)
  // def fromGameRow(row: GameRow): (ID, String) = (row.id, row.json)

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

  override def saveJsonVersionedPlayer(playerId: ID, playerName: String, json: String) = Try {
    val playerRow = PlayerRow(playerId, playerName, json)
    val save = playerRows.insertOrUpdate(playerRow)
    val future = db.run(save)
    val numRows = Await.result(future, timeout)
    logger.debug(s"added ${numRows} player(s)")
  }

  override def findJsonVersionedPlayerByName(name: String) = Try {
    val query = playerRows.filter {_.name === name }
    val future = db.run(query.result)
    val rows = Await.result(future, timeout)
    rows.headOption map { _.json }
  }

  override def saveJsonVersionedGameTransitions(gameId: ID, json: String) = Try {
    val gameRow = GameRow(gameId, json)
    val save = gameRows.insertOrUpdate(gameRow)
    val future = db.run(save)
    val numRows = Await.result(future, timeout)
    logger.debug(s"added ${numRows} game(s)")
  }

  override def findJsonVersionedGameTransitionsById(gameId: ID) = Try {
    val query = playerRows.filter {_.id === gameId }
    val future = db.run(query.result)
    val rows = Await.result(future, timeout)
    rows.headOption map { _.json }
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