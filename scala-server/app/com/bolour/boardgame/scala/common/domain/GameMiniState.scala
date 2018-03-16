/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

/**
  * The state of the game needed by clients.
  *
  * @param lastPlayScore The score of the last play.
  * @param scores The total scores so far.
  * @param noMorePlays Whether the conditions for stopping play have been reached.
  */
case class GameMiniState(
  lastPlayScore: Int,
  scores: List[Int],
  noMorePlays: Boolean
)
