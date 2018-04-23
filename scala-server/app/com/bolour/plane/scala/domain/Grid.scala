/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.plane.scala.domain

import com.bolour.plane.scala.domain.Axis.Axis
import org.slf4j.LoggerFactory

case class Grid[T](cells: List[List[T]]) {

  val logger = LoggerFactory.getLogger(this.getClass)

  val height = cells.size
  if (height == 0)
    throw new IllegalArgumentException(s"grid has no rows")

  val width = cells.head.size

  val sizes = cells map { _.size}
  val rectangular = sizes.forall(_ == width)

  if (!rectangular)
    throw new IllegalArgumentException(s"attempt to create jagged grid with row sizes: ${sizes}")

  lazy val _columns = cells.transpose

  def flatFilter(predicate: T => Boolean): List[T] = filter(predicate).flatten

  def flatten: List[T] = cells.flatten

  def filter(predicate: T => Boolean): List[List[T]] = {
    /* val filteredCells = */
    cells map (row => row filter predicate)
    // Grid(height, width, filteredCells)
  }

  def forall(predicate: T => Boolean): Boolean = flatten.forall(predicate)

  def setN(pointedValues: List[(T, Point)]): Grid[T] = {
    def newValue(point: Point): Option[T] = pointedValues.find(pv => pv._2 == point).map(_._1)
    def cellMaker(r: Int)(c: Int): T =
      newValue(Point(r, c)) match {
        case None => cells(r)(c)
        case Some(value) => value
      }
    Grid(cellMaker _, height, width)
  }

  def rows: List[List[T]] = cells
  def columns: List[List[T]] = _columns

  def inBounds(point: Point): Boolean = {
    val Point(row, col) = point
    row >= 0 && row < height && col >= 0 && col < width
  }

  def get(point: Point): Option[T] =
    if (!inBounds(point)) None else Some(rows(point.row)(point.col))

  def prevCell(point: Point, axis: Axis): Option[T] = adjacent(point, axis, -1)

  def nextCell(point: Point, axis: Axis): Option[T] = adjacent(point, axis, +1)

  def adjacent(point: Point, axis: Axis, direction: Int): Option[T] =
    get(point.adjPoint(axis, direction))

  def numLines(axis: Axis): Int =
    axis match {
      case Axis.X => height
      case Axis.Y => width
    }
}

object Grid {
  def mkRow[T](cellMaker: Int => T, width: Int): List[T] =
    List.range(0, width) map cellMaker

  def apply[T](cellMaker: Int => Int => T, height: Int, width: Int): Grid[T] = {
    val cells = for (r <- List.range(0, height)) yield mkRow(cellMaker(r), width)
    Grid(cells)
  }
}
