package com.bolour.boardgame.scala.server.service

import com.bolour.boardgame.scala.server.domain.{GameBase, Play}

/**
  * History of the plays in the game including its initial state.
  *
  * @param base The initial state.
  * @param plays The successive plays.
  */
case class GameData(base: GameBase, plays: Vector[Play])
