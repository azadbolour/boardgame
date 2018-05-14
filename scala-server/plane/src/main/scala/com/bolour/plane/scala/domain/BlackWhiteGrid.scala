/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.plane.scala.domain

import com.bolour.util.scala.common.{Black, BlackWhite, White}
import com.bolour.plane.scala.domain.Axis.Axis


/**
  * A grid that has black slots meaning disabled/inactive, and white slots
  * that may either contain a value of be empty.
  * A black slot cannot be used at all. An empty slot may be filled at a later time.
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
    grid.adjacent(point, axis, direction)

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

  def isEmpty: Boolean = grid.forall { _.value.isEmpty }

  def isFilled: Boolean = grid.forall {!_.value.isEmpty}

  private def adjHasValue(point: Point, axis: Axis, direction: Int): Boolean = {
    val opt = for {
      BlackWhitePoint(value, _) <- grid.adjacent(point, axis, direction)
    } yield value.fromWhite
    opt.isDefined && opt.get.isDefined
  }

  private def valuedNotValuedTransitionPoint(point: Point, axis: Axis, direction: Int): Boolean = {
    val transitioning = get(point).hasValue && !adjHasValue(point, axis, direction)
    transitioning
  }

  def numLines(axis: Axis): Int = grid.numLines(axis)

  def farthestNeighbor(point: Point, axis: Axis, direction: Int): Point = {
    if (!adjHasValue(point, axis, direction)) point
    else {
      val colinears = (1 until numLines(axis)).toList map point.colinearPoint(axis, direction)
      val maybeFarthest = colinears find { pt => valuedNotValuedTransitionPoint(pt, axis, direction)}
      maybeFarthest.get // Transition is guaranteed at the latest at the boundary.
    }
  }

  def lineNeighbors(point: Point, axis: Axis, direction: Int): List[(T, Point)] = {
    val farthest = farthestNeighbor(point, axis, direction)
    val Point(pointRow, pointCol) = point
    val Point(farRow, farCol) = farthest

    def lineRange(pos: Int, limit: Int) =
      (if (direction == Axis.forward) (pos + 1) to limit else limit until pos).toList

    val points = axis match {
      case Axis.X => lineRange(pointCol, farCol) map { col => Point(pointRow, col) }
      case Axis.Y => lineRange(pointRow, farRow) map { row => Point(row, pointCol) }
    }

    // All neighboring points are guaranteed to have values so 'get' is defined on all of them.
    points map { pt => (get(pt).fromWhite.get, pt)}
  }

  def linesAlongAxis(axis: Axis): List2D[BlackWhite[T]] = {
    val rowValues = this.map(identity)
    axis match {
      case Axis.X => rowValues
      case Axis.Y => rowValues.transpose
    }
  }

  def segmentsAlongAxis(axis: Axis): List[LineSegment[T]] = {
    val dim = numLines(axis)
    val segments = for {
      lineNumber <- (0 until dim).toList
      segment <- segmentsInLine(axis, lineNumber)
    } yield segment
    segments
  }

  def allSegments: List[LineSegment[T]] =
    segmentsAlongAxis(Axis.X) ++ segmentsAlongAxis(Axis.Y)

  def segmentsInLine(axis: Axis, lineNumber: Int): List[LineSegment[T]] = {
    val line = linesAlongAxis(axis)(lineNumber)
    def black(i: Int) = i < 0 || i >= line.length || line(i) == Black()
    def white(i: Int) = !black(i)
    def isBeginSegment(i: Int) = white(i) && black(i - 1)
    def isEndSegment(i: Int) = white(i) && black(i + 1)

    val indices = line.indices.toList
    val begins = indices filter isBeginSegment
    val ends = indices filter isEndSegment
    val liveIntervals = begins zip ends

    val segments = for {
      (intervalBegin, intervalEnd) <- liveIntervals
      begin <- intervalBegin to intervalEnd
      end <- begin to intervalEnd
      segment = BlackWhite.fromWhites(line, begin, end)
    } yield LineSegment(axis, lineNumber, begin, end, segment)
    segments
  }
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
