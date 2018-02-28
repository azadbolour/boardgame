/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis

case class Point(row: Int, col: Int) {
  def nthNeighbor(axis: Axis, direction: Int)(steps: Int): Point = {
    val offset = direction * steps
    axis match {
      case Axis.X => Point(row, col + offset)
      case Axis.Y => Point(row + offset, col)

    }
  }

  def adjPoint(axis: Axis, direction: Int): Point = nthNeighbor(axis, direction)(1)
}

