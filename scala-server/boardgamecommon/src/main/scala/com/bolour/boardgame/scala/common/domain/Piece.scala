package com.bolour.boardgame.scala.common.domain

/**
  * A piece (tile) used in the game.
  *
  * @param value An upper-case alphabetic character.
  * @param id The unique identifier of the piece within a game.
  */
case class Piece(value: Char, id: String)
