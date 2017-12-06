/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.Point
import org.slf4j.LoggerFactory

case class Grid[T](height: Int, width: Int, cells: List[List[T]]) {

  // TODO. Remove parameters height and width. Derive from rectangular 2D list.
  val logger = LoggerFactory.getLogger(this.getClass)

  val sizes = cells map { _.size}
  val rectangular = sizes.forall(_ == width)

  if (!rectangular)
    throw new IllegalArgumentException(s"attempt to create jagged grid with row sizes: ${sizes}")

  // TODO. Check that dimensions are the same and set dimension.
  val dimension = height // TODO. Replace height and width with dimension.
  val _columns = cells.transpose

  def flatFilter(predicate: T => Boolean): List[T] = filter(predicate).flatten

  def flatten: List[T] = cells.flatten

  def filter(predicate: T => Boolean): List[List[T]] = {
    /* val filteredCells = */
    cells map (row => row filter predicate)
    // Grid(height, width, filteredCells)
  }

  def setPoints(pointedValues: List[(T, Point)]): Grid[T] = {
    def newValue(point: Point): Option[T] = pointedValues.find(pv => pv._2 == point).map(_._1)
    def cellMaker(r: Int)(c: Int): T =
      newValue(Point(r, c)) match {
        case None => cells(r)(c)
        case Some(value) => value
      }
    Grid(cellMaker _, height, width)
  }

  def rows = cells
  def columns = _columns

  def cell(point: Point): T = rows(point.row)(point.col)

}

object Grid {
  def mkRow[T](cellMaker: Int => T, width: Int): List[T] =
    List.range(0, width) map cellMaker

  def apply[T](cellMaker: Int => Int => T, height: Int, width: Int): Grid[T] = {
    val cells = for (r <- List.range(0, height)) yield mkRow(cellMaker(r), width)
    Grid(height, width, cells)
  }
}
