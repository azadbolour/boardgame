/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions.InternalGameException

case class Board(dimension: Int, grid: Grid[GridPiece]) {
  def gridPieces: List[GridPiece] =
    grid.flatFilter(gp => !gp.value.isEmpty)

  def addPieces(gridPieces: List[GridPiece]): Board = {
    val pointedPieces = gridPieces map (gp => (gp, gp.point))
    val augmentedGrid = grid.setPoints(pointedPieces)
    Board(dimension, augmentedGrid)
  }

  def rows = grid.rows
  def columns = grid.columns

  def isEmpty = grid.filter(!_.value.isEmpty).flatten.isEmpty

  // TODO. Make sure in-bounds.
  def get(point: Point): Piece = grid.rows(point.row)(point.col).value

  /**
    * TODO. Assumes play is contiguous.
    */
  def stripOfPlay(playPieces: List[PlayPiece]): Strip = {
    if (playPieces.length < 2)
      throw new InternalGameException("play must contain more than 1 piece", null)

    val points = playPieces.map(_.point)

    val head = points.head
    val next = points(1)

    val axis = if (head.row == next.row) Axis.X else Axis.Y
    val (lineNumber, line, begin) = axis match {
      case Axis.X => (head.row, rows(head.row), head.col)
      case Axis.Y => (head.col, columns(head.col), head.row)
    }
    val end = begin + points.length - 1
    val content = Piece.piecesToString(line.map(_.piece)) // converts null chars to blanks
    Strip.lineStrip(axis, lineNumber, content, begin, end)
  }

  def pointIsEmpty(point: Point): Boolean = grid.cell(point).piece.isEmpty

  def inBounds(point: Point): Boolean = {
    val Point(row, col) = point
    inBounds(row) && inBounds(col)
  }

  def inBounds(coordinate: Int): Boolean = coordinate >= 0 && coordinate < dimension

  // TODO. Should really check in bounds and return Option[Point].
  def nthNeighbor(point: Point, axis: Axis, direction: Int)(steps: Int): Option[Point] = {
    val offset = steps * direction
    val Point(row, col) = point
    val nth = axis match {
      case Axis.X => Point(row, col + offset)
      case Axis.Y => Point(row + offset, col)
    }

    if (!inBounds(nth)) None else Some(nth)
  }

}

object Board {
  def apply(dimension: Int, cellMaker: Int => Int => GridPiece) : Board = {
    // TODO. No need here for cellMaker _. Why different from Board (below)?
    val grid = Grid(cellMaker, dimension, dimension)
    Board(dimension, grid)
  }

  def apply(dimension: Int) : Board = {
    def cellMaker(row: Int)(col: Int) = GridPiece(Piece.emptyPiece, Point(row, col))
    Board(dimension, cellMaker _)
  }

  // TODO. Check that grid pieces fall inside the board boundaries.
  def apply(dimension: Int, gridPieces: List[GridPiece]): Board = {
    def maybeGridPiece(r: Int, c: Int) = gridPieces.find(_.point == Point(r, c))
    def cellMaker(row: Int)(col: Int) = {
      maybeGridPiece(row, col) match {
        case Some(gridPiece) => gridPiece
        case None => isEmpty(row, col)
      }
    }
    Board(dimension, cellMaker _)
  }

  def isEmpty(row: Int, col: Int) = GridPiece(Piece.emptyPiece, Point(row, col))

}

