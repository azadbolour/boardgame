package com.bolour.boardgame.scala.server.domain

case class GameTransitions(initialState: GameInitialState, plays: Vector[Play])
