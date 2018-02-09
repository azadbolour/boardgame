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
  * @param cellMaker A function for computing the values of the grid.
  * @tparam T The type of values of cells when they exist.
  */
case class SwissCheeseSparseGrid[T](cellMaker: Int => Int => Option[Option[T]], height: Int, width: Int) {

  import SwissCheeseSparseGrid._

  def pointedCellMaker(row: Int)(col: Int): (Option[Option[T]], Point) =
    (cellMaker(row)(col), Point(row, col))

  val grid = Grid(pointedCellMaker, height, width)

  def rows: List2D[(Opt2[T], Point)] = ???
  def columns: List2D[(Opt2[T], Point)] = ???

  def filter(p: Opt2[T] => Boolean): List2D[T] = ???

  def get(point: Point): Opt2[T] = grid.cell(point)._1
  def set(point: Point, value: Opt2[T]): SwissCheeseSparseGrid[T] = ???

  def next(point: Point, axis: Axis): (Option[Opt2[T]], Point) = ???
  def prev(point: Point, axis: Axis): (Option[Opt2[T]], Point) = ???
  def adjacent(point: Point, axis: Axis, direction: Int): (Option[Opt2[T]], Point) = ???

  def isDead(point: Point): Boolean = get(point).isEmpty
  def isAlive(point: Point): Boolean = !isDead(point)

  def isAliveAndEmpty(point: Point): Boolean = {
    val value = get(point)
    value.isDefined && value.get.isEmpty
  }
  def isAliveAndNonEmpty(point: Point): Boolean = {
    val value = get(point)
    value.isDefined && value.get.isDefined
  }

  def inBounds(point: Point): Boolean = ???
}

object SwissCheeseSparseGrid {
  type Opt2[T] = Option[Option[T]]
  type List2D[T] = List[List[T]]

}
