package com.bolour.plane.scala.domain

import com.bolour.plane.scala.domain.Axis.Axis
import com.bolour.plane.scala.domain.LineSegment.segmentsInLine
import com.bolour.util.scala.common.{Black, BlackWhite, White}


/**
  * A grid that has black slots meaning disabled/inactive, and white slots
  * that may either contain a value of be empty.
  * A dead slot cannot be used at all. An empty slot may be filled at a later time.
  *
  * The slots are represented by a BlackWhite data structure having a Black case,
  * and a White case containing an Option that represents the value (or lack of a value).
  *
  * @param grid Lower-level plain grid.
  * @tparam T The type of values of cells when they exist.
  */
case class BlackWhiteGrid[T](grid: Grid[BlackWhitePoint[T]]) {

  import BlackWhiteGrid._

  def rows: List2D[BlackWhitePoint[T]] = grid.rows
  def columns: List2D[BlackWhitePoint[T]] = grid.columns

  def map[R](f: BlackWhite[T] => R): List2D[R] = {
    def rowMapper(row: List[BlackWhitePoint[T]]): List[R] =
      row map { case BlackWhitePoint(bw, _) => f(bw)}
    rows map rowMapper
  }

  /**
    * If the point is out of bounds get Black.
    */
  def get(point: Point): BlackWhite[T] =
    (grid.get(point) map {_.value}).getOrElse(Black())

  def setN(pointedValues: List[BlackWhitePoint[T]]): BlackWhiteGrid[T] = {
    val pointedPointedValues = pointedValues map {
      case bwPoint => (bwPoint, bwPoint.point)
    }
    val newGrid = grid.setN(pointedPointedValues)
    BlackWhiteGrid(newGrid)
  }

  /**
    * Get the next value-point pair on the grid (None if out of bounds).
    */
  def next(point: Point, axis: Axis): Option[BlackWhitePoint[T]] =
    grid.nextCell(point, axis)

  /**
    * Get the previous value-point pair on the grid (None if out of bounds).
    */
  def prev(point: Point, axis: Axis): Option[BlackWhitePoint[T]] =
    grid.prevCell(point, axis)

  /**
    * Get an adjacent value-point pair on the grid (None if out of bounds).
    */
  def adjacent(point: Point, axis: Axis, direction: Int): Option[BlackWhitePoint[T]] =
    grid.adjacentCell(point, axis, direction)

  def isBlack(point: Point): Boolean = get(point) == Black()

  def isWhite(point: Point): Boolean = !isBlack(point)

  def hasValue(point: Point): Boolean = get(point).hasValue

  def inBounds(point: Point): Boolean = grid.inBounds(point)

  private def fromJustWhites(bwPoints: List[BlackWhitePoint[T]]): List[(T, Point)] = {
    def mapper(bwPoint: BlackWhitePoint[T]): List[(T, Point)] =
      bwPoint match {
        case BlackWhitePoint(bw, point) =>
         bw match {
           case Black() => List()
           case White(None) => List()
           case White(Some(value)) => List((value, point))
         }
    }
    bwPoints flatMap mapper
  }

  def getValues: List[(T, Point)] = fromJustWhites(grid.flatten)

  def isEmpty: Boolean = grid.flatten.forall { _.value.isEmpty }

  def segmentsForLineNumber(axis: Axis, lineNumber: Int): List[LineSegment[T]] = {
    val line = linesAlongAxis(axis)(lineNumber)
    segmentsInLine(axis, lineNumber, line)
  }

  def linesAlongAxis(axis: Axis): List2D[BlackWhite[T]] = {
    val rowValues = this.map(identity)
    axis match {
      case Axis.X => rowValues
      case Axis.Y => rowValues.transpose
    }
  }

  def segmentsAlongAxis(axis: Axis): List[LineSegment[T]] = {
    val lines = linesAlongAxis(axis)
    val segments = for {
      lineNumber <- lines.indices.toList
      segment <- segmentsInLine(axis, lineNumber, lines(lineNumber))
    } yield segment
    segments
  }

  def allSegments: List[LineSegment[T]] =
    segmentsAlongAxis(Axis.X) ++ segmentsAlongAxis(Axis.Y)

}

object BlackWhiteGrid {
  // TODO. Move general type defs to BasicUtil.
  type List2D[T] = List[List[T]]

  def apply[T](cellMaker: Int => Int => BlackWhite[T], height: Int, width: Int): BlackWhiteGrid[T] = {
    def pointedCellMaker(row: Int)(col: Int): BlackWhitePoint[T] =
      BlackWhitePoint(cellMaker(row)(col), Point(row, col))

    val grid = Grid(pointedCellMaker, height, width)
    BlackWhiteGrid(grid)
  }

}
