/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

/**
  * A piece (tile) used in the game.
  *
  * @param value An upper-case alphabetic character.
  * @param id The unique identifier of the piece within a game.
  */
case class Piece(value: Char, id: String)

