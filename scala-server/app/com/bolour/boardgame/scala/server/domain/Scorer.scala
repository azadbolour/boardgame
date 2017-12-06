package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{PlayPiece, Point, ScoreMultiplier}
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplier._
import org.slf4j.LoggerFactory

class Scorer(val dimension: Int) {

  val logger = LoggerFactory.getLogger(this.getClass)

  val middle = dimension / 2 // TODO. Make sure dimension is odd.
  val centerPoint = Point(middle, middle)

  def scoreMultiplier(point: Point): ScoreMultiplier = {
    // logger.info(s"score multiplier point: ${point}")
    val pointRelativeToCenter = translateOrigin(centerPoint)(point)
    multiplierRelativeToCenter(pointRelativeToCenter)
  }

  /**
    * Invariant return - row, col > 0 && row <= col
    */
  def reflectOnFirstOctant(point: Point): Point = {
    val p @ Point(row, col) = reflectOnPositiveQuadrant(point)
    if (row <= col) p else Point(col, row)
  }

  def translateOrigin(origin: Point)(point: Point): Point =
    Point(point.row - origin.row, point.col - origin.col)

  def reflectOnPositiveQuadrant(point: Point): Point =
    Point(Math.abs(point.row), Math.abs(point.col))

  /**
    * Multiplier of a point relative to center as origin: coordinates
    * for this point vary between +/- (dimension / 2)
    */
  def multiplierRelativeToCenter(point: Point): ScoreMultiplier = {
    val representative = reflectOnFirstOctant(point)
    multiplierForFirstOctantRelativeToCenter(representative)
  }

  /**
    * In the coordinate system having the center point as origin,
    * get the multiplier of a point in the first octant.
    * By symmetry the multipliers of any point p is the multiplier
    * of its symmetry representative in the first octant.
    */
  def multiplierForFirstOctantRelativeToCenter(point: Point): ScoreMultiplier = {

    // logger.info(s"point on first octant: ${point}")

    val Point(row, col) = point

    def isCornerPoint: Boolean = point == Point(middle, middle)

    def isMidEdgePoint: Boolean = point == Point(0, middle)

    def isCenterPoint: Boolean = point == Point(0, 0)

    def isDiagonalPoint(centerOffset: Int): Boolean = col - row == centerOffset

    def isQuarterEdgePoint: Boolean = row == middle/2 + 1 && col == middle

    if (isCenterPoint)
      noMultiplier()
    else if (isCornerPoint)
      wordMultiplier(3)
    else if (isMidEdgePoint)
      wordMultiplier(3)
    else if (isQuarterEdgePoint)
      letterMultiplier(2)
    else if (isDiagonalPoint(0)) {
      row match {
        case 1 => letterMultiplier(2)
        case 2 => letterMultiplier(3)
        case _ => wordMultiplier(2)
      }
    }
    else if (isDiagonalPoint(middle/2 + 1)) {
      val nextToMiddle = middle - 1
      col match {
        case `middle` => noMultiplier()
        case `nextToMiddle` => letterMultiplier(3)
        case _ => letterMultiplier(2)
      }
    }
    else noMultiplier()
  }

  def cellScoreMultiplier(row: Int)(col: Int) = scoreMultiplier(Point(row, col))

  val multiplierGrid: Grid[ScoreMultiplier] = Grid(cellScoreMultiplier _, dimension, dimension)

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
