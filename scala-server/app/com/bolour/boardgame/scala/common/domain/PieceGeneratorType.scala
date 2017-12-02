/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

object PieceGeneratorType extends Enumeration {
  type PieceGeneratorType = Value
  val random, cyclic = Value
}
