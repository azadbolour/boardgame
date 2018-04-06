package com.bolour.boardgame.scala.server.service
import com.bolour.boardgame.scala.common.domain.PlayPiece
import com.bolour.boardgame.scala.server.domain.{GameBase, Game, Player}
import com.bolour.util.scala.common.CommonUtil.ID

import scala.util.Success

class GameDaoMock extends GameDao {
  override def createNonExistentTables() = Success(())

  override def deleteAllPlays() = Success(())

  override def deleteAllGames() = Success(())

  override def deleteAllPlayers() = Success(())

  override def addPlayer(player: Player) = Success(())

  override def addGame(game: GameBase) = Success(())

  override def endGame(id: String) = Success(())

  override def addGameState(gameState: Game) = Success(())

  override def addPlay(gameId: ID, playPieces: List[PlayPiece]) = Success(())

  override def findPlayerByName(name: String) = Success(Some(Player("1", "You")))

  override def findGameById(id: ID) = ???
}
