package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplier._
import org.slf4j.LoggerFactory

class Scorer(val dimension: Int, trayCapacity: Int) {

  val logger = LoggerFactory.getLogger(this.getClass)

  val multiplierGrid: Grid[ScoreMultiplier] = mkMultiplierGrid(dimension)

  def scorePlay(playHelper: PlayHelper, playPieces: List[PlayPiece]): Int = {
    val crossingPlays = playHelper.crossingPlays(playPieces)
    val crossScoreList = crossingPlays map { cp => scoreWord(cp)}
    val crossWordsScore = crossScoreList.sum
    val wordScore = scoreWord(playPieces map { pp => (pp.piece.value, pp.point, pp.moved) })
    wordScore + crossWordsScore
  }

  def scoreWord(playInfo: List[(Char, Point, Boolean)]): Int = {
    val multipliers = playInfo map {_._2} map { multiplierGrid.cell(_) }
    val playPieceMultipliers = playInfo zip multipliers
    val letterScores = playPieceMultipliers map {
      case ((letter, _, moved), multiplier) =>
        val factor = if (moved && multiplier.isLetterMultiplier) multiplier.factor else 1
        factor * Piece.worths(letter)
    }
    val baseScore = letterScores.sum

    val aggregateWordMultiplier = (playPieceMultipliers map {
      case ((_, _, moved), multiplier) =>
        if (moved && multiplier.isWordMultiplier) multiplier.factor else 0
    }).sum

    var score = Math.max(1, aggregateWordMultiplier) * baseScore
    if (playInfo.length == trayCapacity)
      score += Scorer.Bonus
    score
  }
}

object Scorer {
  type Score = Int
  val Bonus = 50
  def apply(dimension: Int, trayCapacity: Int): Scorer = new Scorer(dimension, trayCapacity)
}
