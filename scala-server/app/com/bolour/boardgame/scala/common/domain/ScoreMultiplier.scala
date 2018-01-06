package com.bolour.boardgame.scala.common.domain
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._

case class ScoreMultiplier(scoreMultiplierType: ScoreMultiplierType, factor: Int) {
  def isLetterMultiplier: Boolean = scoreMultiplierType == Letter
  def isWordMultiplier: Boolean = scoreMultiplierType == Word
}

// Note. Keeping the score multiplier grid logic in the Common package,
// because it is conceivably useful in client code as well.

object ScoreMultiplier {
  def noMultiplier() = ScoreMultiplier(None, 1)

  def letterMultiplier(factor: Int) = ScoreMultiplier(Letter, factor)

  def wordMultiplier(factor: Int) = ScoreMultiplier(Word, factor)

  def mkMultiplierGrid(dimension: Int): Grid[ScoreMultiplier] = {
    def cellScoreMultiplier(row: Int)(col: Int) = scoreMultiplier(Point(row, col), dimension)
    Grid(cellScoreMultiplier _, dimension, dimension)
  }

  import PointSymmetry._

  def scoreMultiplier(point: Point, dimension: Int): ScoreMultiplier = {
    val center = dimension / 2
    val centerPoint = Point(center, center)
    // logger.info(s"score multiplier point: ${point}")
    val pointRelativeToCenter = translateOrigin(centerPoint)(point)
    multiplierRelativeToCenter(pointRelativeToCenter, dimension)
  }

  /**
    * Multiplier of a point relative to center as origin: coordinates
    * for this point vary between +/- (dimension / 2)
    */
  private def multiplierRelativeToCenter(point: Point, dimension: Int): ScoreMultiplier = {
    val representative = reflectOnFirstOctant(point)
    multiplierForFirstOctantRelativeToCenter(representative, dimension)
  }

  /**
    * In the coordinate system having the center point as origin,
    * get the multiplier of a point in the first octant.
    * By symmetry the multipliers of any point p is the multiplier
    * of its symmetry representative in the first octant.
    */
  private def multiplierForFirstOctantRelativeToCenter(point: Point, dimension: Int): ScoreMultiplier = {
    /**
      * To leverage symmetry, the original point's was translated
      * to be centered at the center of the board as origin,
      * and then reflected to the first octant.
      *
      * The translated and reflected coordinates of the point are then in
      * the range [0, dimension/2]. So we have the following invariant
      * for the input to the parameters to this method:
      * 0 <= point.row <= point.col <= dimension/2.
      */
    val bound = dimension / 2
    // logger.info(s"point on first octant: ${point}")
    val quarter = bound / 2

    val Point(row, col) = point

    def isCornerPoint: Boolean = point == Point(bound, bound)

    def isMidEdgePoint: Boolean = point == Point(0, bound)

    def isCenterPoint: Boolean = point == Point(0, 0)

    def isDiagonalPoint(centerOffset: Int): Boolean = col - row == centerOffset

    def isQuarterEdgePoint: Boolean = row == quarter && col == bound

    if (isCenterPoint)
      wordMultiplier(2)
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
    else if (isDiagonalPoint(quarter + 1)) {
      val nextToMiddle = bound - 1
      col match {
        case `bound` => noMultiplier()
        case `nextToMiddle` => letterMultiplier(3)
        case _ => letterMultiplier(2)
      }
    }
    else noMultiplier()
  }

  object PointSymmetry {
    /**
      * Invariant return - row, col > 0 && row <= col
      */
    def reflectOnFirstOctant(point: Point): Point = {
      val p @ Point(row, col) = reflectOnPositiveQuadrant(point)
      if (row <= col) p else Point(col, row)
    }

    def reflectOnPositiveQuadrant(point: Point): Point =
      Point(Math.abs(point.row), Math.abs(point.col))

    def translateOrigin(origin: Point)(point: Point): Point =
      Point(point.row - origin.row, point.col - origin.col)

  }
}
