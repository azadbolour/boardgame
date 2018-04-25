package com.bolour.boardgame.scala.server.domain

/**
  * Types of play.
  */
sealed abstract class PlayType
object WordPlayType extends PlayType
object SwapPlayType extends PlayType

