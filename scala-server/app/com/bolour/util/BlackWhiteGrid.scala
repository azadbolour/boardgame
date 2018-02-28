package com.bolour.util

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.{Grid, Point}


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

  /** When a related cell is Black, it is as if no related cell exists, and so
    * convert it to None, the same as if a related cell is out of bounds.
    */
  private def unwindBlackWhite(optBWPoint: Option[BlackWhitePoint[T]]): Option[(Option[T], Point)] = {
    optBWPoint match {
      case None => None // on the boundary
      case Some(bwPoint) =>
        val BlackWhitePoint(bw, point) = bwPoint
        bw match {
          case Black() => None // it is like non-existent
          case White(opt) => Some((opt, point))
        }
    }
  }

  def next(point: Point, axis: Axis): Option[(Option[T], Point)] = {
    val optPair = grid.nextCell(point, axis)
    unwindBlackWhite(optPair)
  }

  def prev(point: Point, axis: Axis): Option[(Option[T], Point)] = {
    val optPair = grid.prevCell(point, axis)
    unwindBlackWhite(optPair)
  }

  def adjacent(point: Point, axis: Axis, direction: Int): Option[(Option[T], Point)] = {
    val optPair = grid.adjacentCell(point, axis, direction)
    unwindBlackWhite(optPair)
  }

  def isDead(point: Point): Boolean = get(point) == Black()

  def isAlive(point: Point): Boolean = !isDead(point)

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
