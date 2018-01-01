package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplier._
import org.slf4j.LoggerFactory

class Scorer(val dimension: Int, trayCapacity: Int) {

  val logger = LoggerFactory.getLogger(this.getClass)

  val multiplierGrid: Grid[ScoreMultiplier] = mkMultiplierGrid(dimension)

  def scorePlay(playHelper: CrossWordFinder, playPieces: List[PlayPiece]): Int = {
    val crossingPlays = playHelper.findCrossPlays(playPieces)
    logger.debug(s"crossing plays: ${crossingPlays}")
    val crossScoreList = crossingPlays filter { cp => cp.length > 1 } map { cp => scoreWord(cp)}
    logger.debug(s"crossing score list: ${crossScoreList}")
    val crossWordsScore = crossScoreList.sum
    val wordScore = scoreWord(playPieces map { pp => (pp.piece.value, pp.point, pp.moved) })
    logger.debug(s"principle word score: ${wordScore}")
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
    val numMoves = playInfo.count(_._3)
    if (numMoves == trayCapacity)
      score += Scorer.Bonus
    score
  }
}

object Scorer {
  type Score = Int
  val Bonus = 50
  def apply(dimension: Int, trayCapacity: Int): Scorer = new Scorer(dimension, trayCapacity)
}
