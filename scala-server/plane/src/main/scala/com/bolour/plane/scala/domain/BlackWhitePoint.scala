/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.plane.scala.domain

import com.bolour.util.scala.common.BlackWhite

/**
  * A value at a location on a grid. Black means the location
  * is disabled. White means the location is enabled but may currently be empty.
  */
case class BlackWhitePoint[T](value: BlackWhite[T], point: Point)
