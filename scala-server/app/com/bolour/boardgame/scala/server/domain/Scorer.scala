/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.PlayPiece
import com.bolour.plane.scala.domain.Point
import org.slf4j.LoggerFactory

/**
  * Scores plays.
  *
  * @param pointValues 2D list of values of the board's points.
  */
class Scorer(pointValues: List[List[Int]]) {

  val logger = LoggerFactory.getLogger(this.getClass)

  // val multiplierGrid: Grid[ScoreMultiplier] = mkMultiplierGrid(dimension)

  /**
    * Score a play.
    *
    * @param playPieces Consecutive list of all play pieces for a play.
    *                   Includes both moved and existing pieces forming the play word.
    * @return The score of the play.
    */
  def scorePlay(playPieces: List[PlayPiece]): Int = scoreWord(playPieces)

  // playPieces map { pp => (pp.piece.value, pp.point, pp.moved)

  /**
    * Score an individual word.
    *
    * @param playPieces Consecutive list of all play pieces for a play.
    *                   Includes both moved and existing pieces forming the play word.
    * @return The score of the word.
    */
  def scoreWord(playPieces: List[PlayPiece]): Int = {
    val movedPoints = playPieces filter { _.moved } map {_.point}
    def value: Point => Int = {case Point(row, col) => pointValues(row)(col)}
    val score = movedPoints.foldLeft(0)((total, point) => total + value(point))
    score
  }
}

object Scorer {
  type Score = Int
  def apply(dimension: Int, trayCapacity: Int, pointValues: List[List[Int]]): Scorer =
    new Scorer(pointValues)
}
