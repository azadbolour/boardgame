/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{GridPiece, Piece, Point}

case class Board(height: Int, width: Int, grid: Grid[GridPiece]) {
  def gridPieces: List[GridPiece] =
    grid.flatFilter(gp => !gp.value.isEmpty)

  def addPieces(gridPieces: List[GridPiece]): Board = {
    val pointedPieces = gridPieces map (gp => (gp, gp.point))
    val augmentedGrid = grid.setPoints(pointedPieces)
    Board(height, width, augmentedGrid)
  }

  def rows = grid.rows
  def columns = grid.columns

  def isEmpty = grid.filter(!_.value.isEmpty).flatten.isEmpty

  // TODO. Make sure in-bounds.
  def get(point: Point): Piece = grid.rows(point.row)(point.col).value

}

object Board {
  def apply(height: Int, width: Int, cellMaker: Int => Int => GridPiece) : Board = {
    // TODO. No need here for cellMaker _. Why different from Board (below)?
    val grid = Grid(cellMaker, height, width)
    Board(height, width, grid)
  }

  def apply(height: Int, width: Int) : Board = {
    def cellMaker(row: Int)(col: Int) = GridPiece(Piece.noPiece, Point(row, col))
    Board(height, width, cellMaker _)
  }

  // TODO. Check that grid pieces fall inside the board boundaries.
  def apply(height: Int, width: Int, gridPieces: List[GridPiece]): Board = {
    def maybeGridPiece(r: Int, c: Int) = gridPieces.find(_.point == Point(r, c))
    def cellMaker(row: Int)(col: Int) = {
      maybeGridPiece(row, col) match {
        case Some(gridPiece) => gridPiece
        case None => isEmpty(row, col)
      }
    }
    Board(height, width, cellMaker _)
  }

  def isEmpty(row: Int, col: Int) = GridPiece(Piece.noPiece, Point(row, col))

}

