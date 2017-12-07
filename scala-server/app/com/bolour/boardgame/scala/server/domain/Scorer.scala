package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{Grid, PlayPiece, Point, ScoreMultiplier}
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplier._
import org.slf4j.LoggerFactory

class Scorer(val dimension: Int) {

  val logger = LoggerFactory.getLogger(this.getClass)

  val multiplierGrid: Grid[ScoreMultiplier] = mkMultiplierGrid(dimension)

  def letterScore(letter: Char): Int = 1 // TODO. Add letter scores to pieces.

  def scorePlay(playPieces: List[PlayPiece]): Int = {
    val multipliers = playPieces map {_.point} map { multiplierGrid.cell(_) }
    val playPieceMultipliers = playPieces zip multipliers
    val letterScores = playPieceMultipliers map {
      case (playPiece, squareMultiplier) =>
        val factor = if (playPiece.moved) squareMultiplier.factor else 1
        factor * letterScore(playPiece.piece.value)
    }
    val baseScore = letterScores.sum

    val aggregateWordMultiplier = (playPieceMultipliers map {
      case (playPiece, squareMultiplier) =>
        if (playPiece.moved && squareMultiplier.isWordMultiplier) squareMultiplier.factor else 0
    }).sum

    val score = aggregateWordMultiplier * baseScore
    score
  }
}

object Scorer {
  def apply(dimension: Int): Scorer = new Scorer(dimension)
}
