/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis

case class Point(row: Int, col: Int)

object Point {
  def adjPoint(point: Point, axis: Axis, direction: Int): Point = {
    val Point(row, col) = point
    axis match {
      case Axis.X => Point(row, col + direction)
      case Axis.Y => Point(row + direction, col)

    }
  }
}

