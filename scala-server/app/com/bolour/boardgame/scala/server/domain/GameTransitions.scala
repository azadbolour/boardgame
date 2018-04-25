package com.bolour.boardgame.scala.server.domain

/**
  * History of the plays in the game including its initial state.
  *
  * @param base The initial state.
  * @param plays The successive plays.
  */
case class GameTransitions(base: GameBase, plays: Vector[Play])
