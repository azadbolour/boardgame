package com.bolour.util

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.{Grid, Point}


/**
  * A sparse grid (having empty slots) that also may have disabled/inactive/dead slots.
  * A dead slot cannot be used at all. An empty slot may be filled at a later time.
  *
  * A point value of swiss-cheese sparse grid is represented as Option[Option[T]]
  * where the outer option represents liveness, where the inner option represents
  * existence of content in the cell.
  *
  * @param grid Lower-level plain grid.
  * @tparam T The type of values of cells when they exist.
  */
// case class SwissCheeseSparseGrid[T](cellMaker: Int => Int => Option[Option[T]], height: Int, width: Int) {
case class SwissCheeseSparseGrid[T](grid: Grid[(Option[Option[T]], Point)]) {

  import SwissCheeseSparseGrid._

//  def pointedCellMaker(row: Int)(col: Int): (Option[Option[T]], Point) =
//    (cellMaker(row)(col), Point(row, col))
//
//  val grid = Grid(pointedCellMaker, height, width)

  def rows: List2D[(Opt2[T], Point)] = grid.rows
  def columns: List2D[(Opt2[T], Point)] = grid.columns

  def filter(p: Opt2[T] => Boolean): List2D[T] = ???
  def map[R](f: Opt2[T] => R): List2D[R] = {
    def rowMapper(row: List[(Opt2[T], Point)]): List[R] =
      row map { case (opt2, _) => f(opt2)}
    rows map rowMapper
  }

  def get(point: Point): Opt2[T] = grid.get(point)._1
  // def set(point: Point, value: Opt2[T]): SwissCheeseSparseGrid[T] = ???

  def setN(pointedValues: List[(Opt2[T], Point)]): SwissCheeseSparseGrid[T] = {
    val pointedPointedValues = pointedValues map { case (value, point) => ((value, point), point) }
    val newGrid = grid.setN(pointedPointedValues)
    SwissCheeseSparseGrid(newGrid)
  }

  /**
    * Called on a related cell returned from the lower-level grid:
    * if the related cell is dead, treat it as if it were a boundary and
    * return option None; otherwise return a Some option that flattens the
    * opt2 value unwinding the dead or alive level of the value.
    *
    * The result is an option that tells whether the related cell
    * exists and is alive or not, and if it exists and is alive
    * returns an option that tells whether it is empty, paired
    * with the location (point) of the related cell.
    */
  private def unwindDeadCell(optPair: Option[(Opt2[T], Point)]): Option[(Option[T], Point)] = {
    optPair match {
      case None => None // on the boundary
      case Some((opt2, point)) =>
        opt2 match {
          case None => None // next cell is dead
          case Some(opt) => Some((opt, point))
        }
    }
  }

  def next(point: Point, axis: Axis): Option[(Option[T], Point)] = {
    val optPair = grid.nextCell(point, axis)
    unwindDeadCell(optPair)
  }

  def prev(point: Point, axis: Axis): Option[(Option[T], Point)] = {
    val optPair = grid.prevCell(point, axis)
    unwindDeadCell(optPair)
  }

  def adjacent(point: Point, axis: Axis, direction: Int): Option[(Option[T], Point)] = {
    val optPair = grid.adjacentCell(point, axis, direction)
    unwindDeadCell(optPair)
  }

  def isDead(point: Point): Boolean = get(point).isEmpty
  def isAlive(point: Point): Boolean = !isDead(point)

  def isPointAliveAndEmpty(point: Point): Boolean = {
    val value = get(point)
    value.isDefined && value.get.isEmpty
  }

  def isPointAliveAndNonEmpty(pt: Point): Boolean = isAliveAndNonEmpty(get(pt))

  def inBounds(point: Point): Boolean = ???

  def getAllAliveAndNonEmpty: List[(T, Point)] = {
    val rawPairs = grid flatFilter {case (opt2, _) => isAliveAndNonEmpty(opt2)}
    rawPairs map {case (opt2, point) => (opt2.get.get, point)}
  }
}

object SwissCheeseSparseGrid {
  // TODO. Move general type defs to BasicUtil.
  type Opt2[T] = Option[Option[T]]
  type List2D[T] = List[List[T]]

  def isAliveAndNonEmpty[T](opt2: Option[Option[T]]): Boolean =
    opt2.isDefined && opt2.get.isDefined

  def apply[T](cellMaker: Int => Int => Option[Option[T]], height: Int, width: Int): SwissCheeseSparseGrid[T] = {
    def pointedCellMaker(row: Int)(col: Int): (Option[Option[T]], Point) =
      (cellMaker(row)(col), Point(row, col))

    val grid = Grid(pointedCellMaker, height, width)
    SwissCheeseSparseGrid(grid)

  }

}
