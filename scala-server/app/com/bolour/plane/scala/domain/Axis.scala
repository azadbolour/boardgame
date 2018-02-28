/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.plane.scala.domain

object Axis extends Enumeration {
  type Axis = Value
  val X, Y = Value

  def crossAxis(axis: Axis): Axis = if (axis == X) Y else X
}

