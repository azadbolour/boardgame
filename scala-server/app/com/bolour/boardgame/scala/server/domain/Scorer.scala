package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplier._
import org.slf4j.LoggerFactory

class Scorer(val dimension: Int) {

  val logger = LoggerFactory.getLogger(this.getClass)

  val multiplierGrid: Grid[ScoreMultiplier] = mkMultiplierGrid(dimension)

  def scorePlay(playPieces: List[PlayPiece]): Int = {
    val multipliers = playPieces map {_.point} map { multiplierGrid.cell(_) }
    val playPieceMultipliers = playPieces zip multipliers
    val letterScores = playPieceMultipliers map {
      case (playPiece, multiplier) =>
        val factor = if (playPiece.moved && multiplier.isLetterMultiplier) multiplier.factor else 1
        factor * Piece.worths(playPiece.piece.value)
    }
    val baseScore = letterScores.sum

    val aggregateWordMultiplier = (playPieceMultipliers map {
      case (playPiece, multiplier) =>
        if (playPiece.moved && multiplier.isWordMultiplier) multiplier.factor else 0
    }).sum

    val score = Math.max(1, aggregateWordMultiplier) * baseScore
    score
  }
}

object Scorer {
  type Score = Int
  def apply(dimension: Int): Scorer = new Scorer(dimension)
}
