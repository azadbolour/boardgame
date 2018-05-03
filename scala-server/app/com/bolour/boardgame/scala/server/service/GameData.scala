package com.bolour.boardgame.scala.server.service

import com.bolour.boardgame.scala.server.domain.{Game, GameBase, Play}

import scala.util.Try

/**
  * History of the plays in the game including its initial state.
  *
  * @param base The initial state.
  * @param plays The successive plays.
  */
case class GameData(base: GameBase, plays: Vector[Play])

object GameData {
  def fromGame(game: Game): GameData = GameData(game.gameBase, game.plays)

  // TODO. Implement Game.fromTransitions - recover the current state of the game from its history.ß´
  def toGame(gameData: GameData): Try[Game] = ???

}
