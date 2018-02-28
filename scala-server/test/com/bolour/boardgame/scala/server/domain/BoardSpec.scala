/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import org.slf4j.LoggerFactory
import org.scalatest.{FlatSpec, Matchers}
import com.bolour.boardgame.scala.common.domain.{GridPiece, Piece}
import com.bolour.plane.scala.domain.Point

class BoardSpec extends FlatSpec with Matchers {
  val logger = LoggerFactory.getLogger(this.getClass)

  "board" should "start empty" in {
    val board1 = Board(15)
    board1.gridPieces.size shouldEqual 0

    val noGridPieces: List[GridPiece] = Nil
    val board2: Board = Board(2, noGridPieces)
    board2.gridPieces.size shouldBe 0

    val gridPieces = List(GridPiece(Piece('A', "idA"), Point(0, 0)))
    val board3 = Board(1, gridPieces)
    logger.info(s"${board3}")
    board3.gridPieces.size shouldEqual 1
  }
}
