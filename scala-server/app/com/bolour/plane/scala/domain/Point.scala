/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.plane.scala.domain

import com.bolour.plane.scala.domain.Axis.Axis

case class Point(row: Int, col: Int) {
  def colinearPoint(axis: Axis, direction: Int)(steps: Int): Point = {
    val offset = direction * steps
    axis match {
      case Axis.X => Point(row, col + offset)
      case Axis.Y => Point(row + offset, col)

    }
  }

  def adjPoint(axis: Axis, direction: Int): Point = colinearPoint(axis, direction)(1)
}

