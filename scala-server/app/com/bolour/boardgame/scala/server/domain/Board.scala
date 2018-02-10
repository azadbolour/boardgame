/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions.InternalGameException
import com.bolour.util.SwissCheeseSparseGrid
import com.bolour.util.SwissCheeseSparseGrid.Opt2

case class Board(dimension: Int, grid: SwissCheeseSparseGrid[Piece]) {
  def gridPieces: List[GridPiece] = {
    val piecesAndPoints = grid.getAllAliveAndNonEmpty
    piecesAndPoints map { case (piece, point) => GridPiece(piece, point)}
  }

  // TODO. URGENT. Rename to setN.
  def addPieces(gridPieces: List[GridPiece]): Board = {
    val pairs = gridPieces map
      { case GridPiece(piece, point) => (piece.toAliveAndNonEmptyPiece, point) }
    val augmentedGrid = grid.setN(pairs)
    Board(dimension, augmentedGrid)
  }

  private def rows = grid.rows
  private def columns = grid.columns

  def isEmpty = grid.getAllAliveAndNonEmpty.isEmpty

  // TODO. Make sure in-bounds.
  def get(point: Point): Piece = {
    val (opt2Piece, _) = grid.rows(point.row)(point.col)
    Piece.fromAliveAndNonEmptyPiece(opt2Piece)
  }

  def lineToString(pointedCells: List[(Opt2[Piece], Point)]): String = {
    val pieces = pointedCells map { _._1 } map { Piece.fromAliveAndNonEmptyPiece }
    Piece.piecesToString(pieces)
  }

  /**
    * TODO. Assumes play is contiguous.
    */
  def stripOfPlay(playPieces: List[PlayPiece]): Strip = {
    val len = playPieces.length
    if (len == 0)
      throw new InternalGameException("no pieces in play", null)

    if (len == 1) {
      val PlayPiece(_, point, _) = playPieces.head
      // Arbitrarily consider the single play it as a horizontal play.
      val theRow = rows(point.row)
      val content = lineToString(theRow)
      return Strip.lineStrip(Axis.X, point.row, content, point.col, point.col)
    }

    val points = playPieces.map(_.point)

    val head = points.head
    val next = points(1)

    val axis = if (head.row == next.row) Axis.X else Axis.Y
    val (lineNumber, line, begin) = axis match {
      case Axis.X => (head.row, rows(head.row), head.col)
      case Axis.Y => (head.col, columns(head.col), head.row)
    }
    val end = begin + points.length - 1
    // val content = Piece.piecesToString(line.map(_.piece)) // converts null chars to blanks
    val content = lineToString(line)
    Strip.lineStrip(axis, lineNumber, content, begin, end)
  }

  def pointIsEmpty(point: Point): Boolean = grid.isPointAliveAndEmpty(point)

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

  private def toGridPieceOption(pointedPairOpt: Option[(Option[Piece], Point)]): Option[GridPiece] = {
    pointedPairOpt match {
      case None => None
      case Some((optPiece, point)) =>
        val piece = Piece.fromOption(optPiece)
        Some(GridPiece(piece, point))
    }
  }

  def nextCell(point: Point, axis: Axis): Option[GridPiece] = {
    val pointedPairOpt = grid.next(point, axis)
    toGridPieceOption(pointedPairOpt)
  }

  def prevCell(point: Point, axis: Axis): Option[GridPiece] = {
    val pointedPairOpt = grid.prev(point, axis)
    toGridPieceOption(pointedPairOpt)
  }

  def adjacentCell(point: Point, axis: Axis, direction: Int): Option[GridPiece] = {
    val pointedPairOpt = grid.adjacent(point, axis, direction)
    toGridPieceOption(pointedPairOpt)
  }

  def rowsAsPieces: List[List[Piece]] = grid map Piece.fromAliveAndNonEmptyPiece
  def columnsAsPieces: List[List[Piece]] = rowsAsPieces.transpose

}

object Board {
  def apply(dimension: Int, cellMaker: Int => Int => GridPiece) : Board = {
    def op2CellMaker(row: Int)(col: Int): Opt2[Piece] = {
      val GridPiece(piece, point) = cellMaker(row)(col)
      piece.toAliveAndNonEmptyPiece
    }
    val grid = SwissCheeseSparseGrid[Piece](op2CellMaker _, dimension, dimension)
    Board(dimension, grid)
  }

  def apply(dimension: Int) : Board = {
    def cellMaker(row: Int)(col: Int): Opt2[Piece] = Piece.emptyPiece.toAliveAndNonEmptyPiece
    val grid = SwissCheeseSparseGrid[Piece](cellMaker _, dimension, dimension)
    Board(dimension, grid)

  }

  // TODO. Check that grid pieces fall inside the board boundaries.
  def apply(dimension: Int, gridPieces: List[GridPiece]): Board = {
    def maybeGridPiece(r: Int, c: Int) = gridPieces.find(_.point == Point(r, c))
    def cellMaker(row: Int)(col: Int) = {
      maybeGridPiece(row, col) match {
        case Some(gridPiece) => gridPiece
        case None => emptyGridPiece(row, col)
      }
    }
    Board(dimension, cellMaker _)
  }

  def emptyGridPiece(row: Int, col: Int) = GridPiece(Piece.emptyPiece, Point(row, col))

}

