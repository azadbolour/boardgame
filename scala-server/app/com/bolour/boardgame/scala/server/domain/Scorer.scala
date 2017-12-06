package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{PlayPiece, Point, ScoreMultiplier}
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplier._

class Scorer(dimension: Int) {

  val middle = dimension / 2 // TODO. Make sure dimension is odd.
  val centerPoint = Point(middle, middle)

  /**
    * The score multiplier applicable to a board cell.
    */
  def cellScoreMultiplier(row: Int)(col: Int): ScoreMultiplier = {
    val point = Point(row, col)

    if (isCenterPoint(point))
      noMultiplier()
    else if (isCornerPoint(point))
      wordMultiplier(3)
    else if (isMidEdgePoint(point))
      wordMultiplier(3)
    else if (isQuarterEdgePoint(point))
      letterMultiplier(2)
    else if (isDiagonalPoint(point, 0)) {
      point.row match {
        case 2 => letterMultiplier(3)
        case _ => letterMultiplier(2)
      }
    }
    else if (isDiagonalPoint(point, middle/2 + 1)) {
      val nextToMiddle = middle - 1
      point.row match {
        case `middle` => noMultiplier()
        case `nextToMiddle` => letterMultiplier(3)
        case _ => letterMultiplier(2)
      }
    }
    else noMultiplier()
  }

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


  def translateOrigin(origin: Point)(point: Point): Point =
    Point(point.row - origin.row, point.col - origin.col)

  def reflectOnPositiveQuadrant(point: Point): Point =
    Point(Math.abs(point.row), Math.abs(point.col))

  def reflectOnFirstQuadrant(point: Point): Point = {
    val fromCenter = translateOrigin(centerPoint)(point)
    val positiveOffCenter = reflectOnPositiveQuadrant(fromCenter)
    positiveOffCenter
  }

  /**
    * Invariant return - row, col > 0 && row <= col
    */
  def reflectOnFirstOctant(point: Point): Point = {
    val p @ Point(row, col) = reflectOnFirstQuadrant(point)
    if (row <= col) p else Point(col, row)
  }

  def isCornerPoint(point: Point): Boolean = {
    val symmetrical = reflectOnFirstOctant(point)
    symmetrical == Point(middle, middle)
  }

  def isMidEdgePoint(point: Point): Boolean = {
    val symmetrical = reflectOnFirstQuadrant(point)
    symmetrical == Point(0, middle)
  }

  def isCenterPoint(point: Point): Boolean = point == centerPoint

  def isDiagonalPoint(point: Point, centerOffset: Int): Boolean = {
    val Point(row, col) = reflectOnFirstOctant(point)
    col - row == centerOffset
  }

  def isQuarterEdgePoint(point: Point): Boolean = {
    val Point(row, col) = reflectOnFirstOctant(point)
    row == middle / 2 && col == middle
  }

}
