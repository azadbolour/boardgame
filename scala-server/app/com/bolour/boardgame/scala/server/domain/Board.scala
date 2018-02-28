/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions.InternalGameException
import com.bolour.util.BasicUtil.inverseMultiValuedMapping
import com.bolour.util._

case class Board(dimension: Int, grid: BlackWhiteGrid[Piece]) {

  import Board._
  def gridPieces: List[GridPiece] = {
    val piecesAndPoints = grid.getValues
    piecesAndPoints map { case (piece, point) => GridPiece(piece, point)}
  }

  def setN(gridPieces: List[GridPiece]): Board = {
    val bwPoints = gridPieces map
      { case GridPiece(piece, point) => BlackWhitePoint(pieceToBlackWhite(piece), point) }
    val augmentedGrid = grid.setN(bwPoints)
    Board(dimension, augmentedGrid)
  }

  def setDeadPoints(deadPoints: List[Point]): Board = {
    def deadGridPiece(point: Point) = GridPiece(Piece.deadPiece, point)
    val gridPieces = deadPoints map deadGridPiece
    setN(gridPieces)
  }

  private def rows = grid.rows
  private def columns = grid.columns

  def isEmpty: Boolean = grid.isEmpty

  // TODO. Make sure in-bounds.
  def get(point: Point): Piece = blackWhiteToPiece(grid.get(point))

  def lineToString(bwPoints: List[BlackWhitePoint[Piece]]): String = {
    val pieces = bwPoints map { case BlackWhitePoint(value, _) => blackWhiteToPiece(value) }
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

  def pointIsEmpty(point: Point): Boolean = grid.get(point).isEmpty

  def inBounds(point: Point): Boolean = {
    val Point(row, col) = point
    inBounds(row) && inBounds(col)
  }

  def inBounds(coordinate: Int): Boolean = coordinate >= 0 && coordinate < dimension

  def nthNeighbor(point: Point, axis: Axis, direction: Int)(steps: Int): Option[Point] = {
    val nth = point.nthNeighbor(axis, direction)(steps)
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

  def next(point: Point, axis: Axis): Option[GridPiece] = {
    val pointedPairOpt = grid.next(point, axis)
    toGridPieceOption(pointedPairOpt)
  }

  def prev(point: Point, axis: Axis): Option[GridPiece] = {
    val pointedPairOpt = grid.prev(point, axis)
    toGridPieceOption(pointedPairOpt)
  }

  def adjacent(point: Point, axis: Axis, direction: Int): Option[GridPiece] = {
    val pointedPairOpt = grid.adjacent(point, axis, direction)
    toGridPieceOption(pointedPairOpt)
  }

  def hasRealNeighbor(point: Point, axis: Axis): Boolean = {
    val nextOpt = next(point, axis)
    if (nextOpt.isDefined && nextOpt.get.piece.isReal)
      return true
    val prevOpt = prev(point, axis)
    if (prevOpt.isDefined && prevOpt.get.piece.isReal)
      return true
    return false
  }

  def rowsAsPieces: List[List[Piece]] = grid map { bw => blackWhiteToPiece(bw) }
  def columnsAsPieces: List[List[Piece]] = rowsAsPieces.transpose

  def playableEmptyStrips(traySize: Int): List[Strip] = {
    val center = dimension/2
    val centerRowAsPieces = rowsAsPieces(center)
    val centerRowAsString = Piece.piecesToString(centerRowAsPieces) // converts null chars to blanks
    val strips = Strip.stripsInLine(Axis.X, dimension, center, centerRowAsString)
    val conformantStrips = strips.filter { strip => strip.begin <= center && strip.end >= center}
    conformantStrips
  }

  def playableStrips(traySize: Int): List[Strip] = {
    // val traySize = tray.pieces.length
    // val allStrips = computeAllStrips
    val allStrips = computeAllLiveStrips
    def hasFillableBlanks = (s: Strip) => s.numBlanks > 0 && s.numBlanks <= traySize
    val conformantStrips1 = allStrips.filter(hasFillableBlanks)
    val conformantStrips2 = conformantStrips1.filter(_.hasAnchor)
    val conformantStrips3 = conformantStrips2.filter(stripIsDisconnectedInLine)
    conformantStrips3
  }

  def potentialPlayableStrips(axis: Axis, trayCapacity: Int): List[Strip] = {
    // val traySize = tray.capacity
    val allStrips = computeAllLiveStrips(axis)
    def hasFillableBlanks = (s: Strip) => s.numBlanks > 0 && s.numBlanks <= trayCapacity
    val conformantStrips1 = allStrips.filter(hasFillableBlanks)
    val conformantStrips2 = conformantStrips1.filter(stripIsDisconnectedInLine)
    conformantStrips2
  }

  // TODO. Obsolete remove once replacement is tested. Also remove obsolete dependencies.
  def potentialPlayableStripsForBlanks(axis: Axis, trayCapacity: Int): Map[Point, List[Strip]] = {
    val ppStrips = potentialPlayableStrips(axis, trayCapacity)
    inverseMultiValuedMapping((strip: Strip) => strip.blankPoints)(ppStrips)
  }

  def stripIsDisconnectedInLine(strip: Strip): Boolean = {
    val firstPoint = strip.point(0)
    val lastPoint = strip.point(strip.end - strip.begin)
    val maybePrevPiece = prev(firstPoint, strip.axis).map {_.value}
    val maybeNextPiece = next(lastPoint, strip.axis).map {_.value}
    def isSeparator(maybePiece: Option[Piece]): Boolean = {
      maybePiece match {
        case None => true
        case Some(piece) => piece.isEmpty
      }
    }
    isSeparator(maybePrevPiece) && isSeparator(maybeNextPiece)
  }

  def computeAllStrips: List[Strip] = {
    def rowsAsStrings: List[String] = rowsAsPieces.map(Piece.piecesToString)
    def columnsAsStrings: List[String] = columnsAsPieces.map(Piece.piecesToString)
    val xStrips = Strip.allStrips(Axis.X, dimension, rowsAsStrings)
    val yStrips = Strip.allStrips(Axis.Y, dimension, columnsAsStrings)
    xStrips ++ yStrips
  }

  def computeAllLiveStrips : List[Strip] =
    computeAllLiveStrips(Axis.X) ++ computeAllLiveStrips(Axis.Y)

  def computeAllLiveStrips(axis: Axis): List[Strip] = {
    axis match {
      case Axis.X =>
        def rowsAsStrings: List[String] = rowsAsPieces.map(Piece.piecesToString)
        Strip.allLiveStrips(Axis.X, rowsAsStrings)
      case Axis.Y =>
        def columnsAStrings: List[String] = columnsAsPieces.map(Piece.piecesToString)
        Strip.allLiveStrips(Axis.Y, columnsAStrings)
    }
  }

  def enclosingStripsOfBlankPoints(axis: Axis): Map[Point, List[Strip]] = {
    val stripsEnclosingBlanks = computeAllLiveStrips(axis) filter { _.numBlanks > 0 }
    inverseMultiValuedMapping((strip: Strip) => strip.blankPoints)(stripsEnclosingBlanks)
  }

  def playableEnclosingStripsOfBlankPoints(axis: Axis, trayCapacity: Int): Map[Point, List[Strip]] = {
    val enclosing = enclosingStripsOfBlankPoints(axis)
    val playable = enclosing mapValues { (strips: List[Strip]) =>
      strips filter { (s: Strip) =>
        s.numBlanks <= trayCapacity &&
          stripIsDisconnectedInLine(s) &&
          // Can't play to a single blank strip - would have no anchor.
          s.content.length > 1
      }
    }
    playable
  }

}

object Board {
  def apply(dimension: Int, cellMaker: Int => Int => GridPiece) : Board = {
    def bwCellMaker(row: Int)(col: Int): BlackWhite[Piece] = {
      val GridPiece(piece, point) = cellMaker(row)(col)
      pieceToBlackWhite(piece)
    }
    val grid = BlackWhiteGrid[Piece](bwCellMaker _, dimension, dimension)
    Board(dimension, grid)
  }

  def apply(dimension: Int) : Board = {
    def cellMaker(row: Int)(col: Int): BlackWhite[Piece] = White(None)
    val grid = BlackWhiteGrid[Piece](cellMaker _, dimension, dimension)
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

  def pieceToBlackWhite(piece: Piece): BlackWhite[Piece] = {
    if (piece == Piece.deadPiece)
      Black()
    else if (piece == Piece.emptyPiece)
      White(None)
    else
      White(Some(piece))
  }

  def blackWhiteToPiece(bw: BlackWhite[Piece]): Piece = {
    bw match {
      case Black() => Piece.deadPiece
      case White(None) => Piece.emptyPiece
      case White(Some(piece)) => piece
    }
  }

}

