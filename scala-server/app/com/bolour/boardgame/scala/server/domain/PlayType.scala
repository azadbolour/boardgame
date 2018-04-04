package com.bolour.boardgame.scala.server.domain

sealed abstract class PlayType
object WordPlayType extends PlayType
object SwapPlayType extends PlayType

