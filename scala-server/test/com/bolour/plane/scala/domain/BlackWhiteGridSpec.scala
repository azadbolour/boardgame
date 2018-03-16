/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.plane.scala.domain

import com.bolour.util.scala.common.{Black, BlackWhite, White}
import org.scalatest.{FlatSpec, Matchers}

class BlackWhiteGridSpec extends FlatSpec with Matchers {

  val dim = 5

  val black: BlackWhite[Char] = Black[Char]
  def justWhite(ch: Char): BlackWhite[Char] = White(Some(ch))
  def emptyWhite: BlackWhite[Char] = White(None)

  val initRows = List(
    List(black,           emptyWhite,      justWhite('A'),  justWhite('B'),  emptyWhite),
    List(emptyWhite,      emptyWhite,      justWhite('A'),  justWhite('B'),  black),
    List(black,           black,           black,           black,           justWhite('A')),
    List(justWhite('A'),  justWhite('B'),  justWhite('C'),  justWhite('D'),  justWhite('E')),
    List(justWhite('A'),  justWhite('B'),  emptyWhite,      justWhite('D'),  emptyWhite)
  )

  def cellMaker(row: Int)(col: Int): BlackWhite[Char] =
    initRows(row)(col)

  val grid: BlackWhiteGrid[Char] = BlackWhiteGrid(cellMaker, dim, dim)

  "grid" should "compute lineNeighbors" in {
    val neighbors1 = grid.lineNeighbors(Point(3, 0), Axis.X, Axis.forward)
    val chars = neighbors1 map { _._1 }
    chars.mkString shouldEqual "BCDE"

    val neighbors2 = grid.lineNeighbors(Point(1, 1), Axis.Y, Axis.forward)
    neighbors2 shouldEqual List()


  }

}
