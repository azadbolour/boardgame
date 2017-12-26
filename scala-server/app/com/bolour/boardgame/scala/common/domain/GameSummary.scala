/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

/**
  * Summary of game reported to clients after the last play.
  *
  * @param stopInfo Data about why the last play was reached.
  * @param endOfPlayScores The additional scores based on state of trays when the game stopped.
  * @param totalScores The final game score including play scores and the end of play scores.
  */
case class GameSummary(stopInfo: StopInfo, endOfPlayScores: List[Int], totalScores: List[Int])
