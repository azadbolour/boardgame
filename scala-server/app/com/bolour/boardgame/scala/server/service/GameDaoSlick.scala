///*
// * Copyright 2017-2018 Azad Bolour
// * Licensed under GNU Affero General Public License v3.0 -
// *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
// */
//package com.bolour.boardgame.scala.server.service
//
//import java.time.Instant
//
//import scala.concurrent.Await
//import scala.concurrent.duration._
//import slick.jdbc.JdbcProfile
//import slick.jdbc.JdbcBackend.Database
//import com.typesafe.config.Config
//import com.bolour.util.scala.common.CommonUtil.ID
//import com.bolour.boardgame.scala.common.domain.{PieceProviderType, PlayPiece}
//import com.bolour.boardgame.scala.server.domain.{GameBase, Game, Player, PieceProvider}
//import com.bolour.util.scala.server.SlickUtil.{CustomColumnTypes, configuredDbAndProfile, tableNames}
//import org.slf4j.LoggerFactory
//
//import scala.util.{Success, Try}
//
//class GameDaoSlick(val profile: JdbcProfile, db: Database) extends GameDao {
//
//  val logger = LoggerFactory.getLogger(this.getClass)
//
//  val playerTableName = "player"
//  val gameTableName = "game"
//  val gameStateTableName = "game-state"
//  // Ue large timeout to avoid internal error on overloaded machine.
//  val timeout = 5.seconds
//
//  def tableMap = Map(playerTableName -> playerRows, gameTableName -> gameRows)
//  def allTableNames = tableMap.keySet.toList
//
//  val customColumnTypes = new CustomColumnTypes(profile)
//  import customColumnTypes.javaTimeType // implicit needs for Instant.
//
//  import profile.api._
//
//  case class PlayerRow(id: ID, name: String)
//  class PlayerTable(tag: Tag) extends Table[PlayerRow](tag, playerTableName) {
//    def id = column[ID]("id", O.PrimaryKey)
//    def name = column[String]("name")
//
//    def * = (id, name).mapTo[PlayerRow]
//  }
//  def playerRows = TableQuery[PlayerTable]
//  def toPlayerRow(player: Player): PlayerRow = PlayerRow(player.id, player.name)
//  def fromPlayerRow(row: PlayerRow): Player = Player(row.id, row.name)
//
//  case class GameRow(id: ID, dimension: Int, trayCapacity: Int, languageCode: String, pieceProviderType: String, playerId: ID, startTime: Instant, endTime: Option[Instant])
//  class GameTable(tag: Tag) extends Table[GameRow](tag, gameTableName) {
//    def id = column[ID]("id", O.PrimaryKey)
//    def dimension = column[Int]("dimension")
//    def trayCapacity = column[Int]("tray-capacity")
//    def languageCode = column[String]("language-code")
//    def pieceProviderType = column[String]("piece-provider-type")
//    def playerId = column[ID]("player-id")
//    def startTime = column[Instant]("start-time")
//    def endTime = column[Option[Instant]]("end-time")
//
//    def player = foreignKey("player_fk", playerId, playerRows)(
//      _.id, onUpdate=ForeignKeyAction.Restrict, onDelete=ForeignKeyAction.Restrict
//    )
//
//    def * = (id, dimension, trayCapacity, languageCode, pieceProviderType, playerId, startTime, endTime).mapTo[GameRow]
//  }
//  def gameRows = TableQuery[GameTable]
//
//  def toGameRow(game: GameBase): GameRow = {
//    GameRow(game.id, game.dimension, game.trayCapacity, game.languageCode, game.pieceProviderType.toString, game.playerId, game.startTime, game.endTime)
//  }
//  def fromGameRow(row: GameRow): GameBase =
//    GameBase(row.id, row.dimension, row.trayCapacity, row.languageCode,
//      PieceProviderType.fromString(row.pieceProviderType), hackPointValues(row.dimension), row.playerId, row.startTime, row.endTime, Nil, Nil, Nil)
//
//  // TODO. Add game and play tables.
//
//  // We are not yet saving the point values. So for now hack in a basic set of point values.
//  // TODO. Save and restore point values.
//  private def hackPointValues(dimension: Int): List[List[Int]] = List.fill(dimension, dimension)(1)
//
//
//  override def createNonExistentTables(): Try[Unit] = Try {
//    val existingTableNames = tableNames(db)
//    val neededTableNames = allTableNames diff existingTableNames
//    val creates = neededTableNames map {name => tableMap(name).schema.create}
//    val future = db.run(DBIO.seq(creates:_*))
//    Await.result(future, timeout)
//  }
//
//  override def deleteAllGames(): Try[Unit] = Try {
//    gameRows.delete
//  }
//
//  override def deleteAllPlayers(): Try[Unit] = Try {
//    playerRows.delete
//  }
//
//  // TODO. Implement.
//  override def deleteAllPlays(): Try[Unit] = Success(())
//
//  override def addPlayer(player: Player): Try[Unit] = Try {
//    val playerRow = toPlayerRow(player)
//    val insert = playerRows += playerRow
//    val future = db.run(insert)
//    val numRows = Await.result(future, timeout)
//    logger.debug(s"added ${numRows} player(s)")
//  }
//
//  override def addGame(gameBase: GameBase): Try[Unit] = Try {
//    val gameRow = toGameRow(gameBase)
//    val insert = gameRows += gameRow
//    val future = db.run(insert)
//    val numRows = Await.result(future, timeout)
//
//  }
//
//  override def endGame(id: String): Try[Unit] = Try {
//    val query = (gameRows.filter {_.id === id }) map {_.endTime}
//    val now = Instant.now()
//    val action = query.update(Some(now))
//    val future = db.run(action)
//    val rows = Await.result(future, timeout)
//    ()
//  }
//
//  override def addGameState(gameState: Game): Try[Unit] = ???
//
//  override def addPlay(gameId: String, playPieces: List[PlayPiece]): Try[Unit] = ???
//
//  override def findPlayerByName(name: String): Try[Option[Player]] = Try {
//    val query = playerRows.filter {_.name === name }
//    val future = db.run(query.result)
//    val rows = Await.result(future, timeout)
//    rows.headOption map fromPlayerRow
//  }
//
//  override def findGameById(id: String): Try[Option[GameBase]] = Try {
//    val query = gameRows.filter {_.id === id }
//    val future = db.run(query.result)
//    val rows = Await.result(future, timeout)
//    rows.headOption map fromGameRow
//  }
//
//}
//
//object GameDaoSlick {
//
//  val dbConfigPrefix = "service.db"
//  def confPath(pathInDb: String) =  s"${dbConfigPrefix}.${pathInDb}"
//
//  def apply(dbName: String, config: Config): GameDaoSlick = {
//    val dbConfigPath = confPath(dbName)
//    val (myDb, myProfile) = configuredDbAndProfile(dbConfigPath)
//    new GameDaoSlick(myProfile, myDb)
//  }
//}
