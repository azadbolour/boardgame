/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.plane.scala.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions.InternalGameException
import com.bolour.plane.scala.domain._
import com.bolour.util.scala.common.CommonUtil.inverseMultiValuedMapping
import com.bolour.util.scala.common.{Black, BlackWhite, White}

case class Board(dimension: Int, grid: BlackWhiteGrid[Piece]) {

  import Board._

  /**
    * Is the board empty? Empty means all of its points are White(None)?
    * Note that a black point makes the board non-empty in this
    * interpretation.
    */
  def isEmpty: Boolean = grid.isEmpty

  /**
    * If there is a piece at the given point return it in Some, otherwise
    * return None.
    */
  def getPiece(point: Point): Option[Piece] = {
    val bw = grid.get(point)
    bw match {
      case White(Some(piece)) => Some(piece)
      case _ => None
    }
  }

  /**
    * Get the value of a point on the board (if the point is out of bounds return black -
    * same as if the point is black).
    */
  def get(point: Point): BlackWhite[Piece] = grid.get(point)

  /**
    * Get the board pieces and their locations as grid pieces.
    */
  def gridPieces: List[GridPiece] = {
    val piecesAndPoints = grid.getValues
    piecesAndPoints map { case (piece, point) => GridPiece(piece, point)}
  }

  /**
    * Update a number of values of the board returning the updated board.
    * @param bwPoints List of (piece, point) pairs (housed in BlackWhitePoints) to update.
    *                 Out of bound points are ignored.
    */
  def setN(bwPoints: List[BlackWhitePoint[Piece]]): Board = {
    val augmentedGrid = grid.setN(bwPoints)
    Board(dimension, augmentedGrid)
  }

  /**
    * Similar to setN but provides the (piece, point) pairs in a list of GridPieces.
    */
  def setGridPieces(gridPieces: List[GridPiece]): Board = {
    val bwPoints = gridPieces map { case GridPiece(piece, point) => BlackWhitePoint(White(Some(piece)), point)}
    setN(bwPoints)
  }

  /**
    * Set a number of the board's points to black.
    */
  def setBlackPoints(deadPoints: List[Point]): Board = {
    val bwPoints = deadPoints map { point => BlackWhitePoint(Black[Piece](), point) }
    setN(bwPoints)
  }

  private def rows = grid.rows
  private def columns = grid.columns

  private def lineToString(bwPoints: List[BlackWhitePoint[Piece]]): String = {
    val chars = bwPoints map { case BlackWhitePoint(bwPiece, _) => Piece.bwPieceToChar(bwPiece) }
    chars.mkString
  }

  /**
    * Given a play in terms of a list of play pieces, find the strip
    * on which the play is made.
    *
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
    val content = lineToString(line)
    Strip.lineStrip(axis, lineNumber, content, begin, end)
  }

  def pointIsEmpty(point: Point): Boolean = grid.get(point).isEmpty

  def inBounds(point: Point): Boolean = {
    val Point(row, col) = point
    inBounds(row) && inBounds(col)
  }

  def inBounds(coordinate: Int): Boolean = coordinate >= 0 && coordinate < dimension

  def colinearPoint(point: Point, axis: Axis, direction: Int)(steps: Int): Option[Point] = {
    val nth = point.colinearPoint(axis, direction)(steps)
    if (!inBounds(nth)) None else Some(nth)
  }

  /**
    * Considering a point to be a neighbor if it is recursively adjacent to
    * the given point in the given direction, find the farthest one in that direction.
    */
  def farthestNeighbor1(point: Point, axis: Axis, direction: Int): Point = {

    def outOfBoundsOrEmpty(oPoint: Option[Point]): Boolean =
      oPoint.isEmpty || pointIsEmpty(oPoint.get)

    def adjacent(p: Point): Option[Point] = colinearPoint(p, axis, direction)(1)

    def isBoundary(p: Point): Boolean =
      !pointIsEmpty(p) && outOfBoundsOrEmpty(adjacent(p))

    // The starting point is special because it is empty.
    if (outOfBoundsOrEmpty(adjacent(point)))
      return point

    val neighbors = (1 until dimension).toList map colinearPoint(point, axis, direction)
    val farthest = neighbors find (_.exists(isBoundary))
    farthest.get.get // A boundary always exists.
  }

  def farthestNeighbor(point: Point, axis: Axis, direction: Int): Point = {

    def isBoundary(p: Point): Boolean =
      getPiece(p).isDefined && getPiece(p.adjPoint(axis, direction)).isEmpty

    // The starting point is special because it is empty.
    if (getPiece(point.adjPoint(axis, direction)).isEmpty)
      return point

    val colinears = (1 until dimension).toList map colinearPoint(point, axis, direction)
    val farthest = colinears find (_.exists(isBoundary))
    farthest.get.get // A boundary always exists.
  }

  /**
    * Get the value of the next point on the grid (None if next is off the grid).
    */
  def next(point: Point, axis: Axis): Option[BlackWhite[Piece]] =
    grid.next(point, axis) map { _.value }

  /**
    * Get the value of the previous point on the grid (None if previous is off the grid).
    */
  def prev(point: Point, axis: Axis): Option[BlackWhite[Piece]] =
    grid.prev(point, axis) map { _.value }

  /**
    * Get the value of an adjacent point on the grid (None if adjacent is off the grid).
    */
  def adjacent(point: Point, axis: Axis, direction: Int): Option[BlackWhite[Piece]] =
    grid.adjacent(point, axis, direction) map { _.value }


  def hasRealNeighbor(point: Point, axis: Axis): Boolean = {
    val nextOpt = next(point, axis)
    if (nextOpt.isDefined && nextOpt.get.hasValue)
      return true
    val prevOpt = prev(point, axis)
    if (prevOpt.isDefined && prevOpt.get.hasValue)
      return true
    false
  }

  def playableEmptyStrips(traySize: Int): List[Strip] = {
    val center = dimension/2
    val strips = grid.segmentsForLineNumber(Axis.X, center) map lineSegmentToStrip
    val conformantStrips = strips.filter { strip => strip.begin <= center && strip.end >= center}
    conformantStrips
  }

  def playableStrips(traySize: Int): List[Strip] = {
    val allStrips = computeAllLiveStrips
    def hasFillableBlanks = (s: Strip) => s.numBlanks > 0 && s.numBlanks <= traySize
    val conformantStrips1 = allStrips.filter(hasFillableBlanks)
    val conformantStrips2 = conformantStrips1.filter(_.hasAnchor)
    val conformantStrips3 = conformantStrips2.filter(stripIsDisconnectedInLine)
    conformantStrips3
  }

  def potentialPlayableStrips(axis: Axis, trayCapacity: Int): List[Strip] = {
    val allStrips = grid.segmentsAlongAxis(axis) map lineSegmentToStrip
    def hasFillableBlanks = (s: Strip) => s.numBlanks > 0 && s.numBlanks <= trayCapacity
    val conformantStrips1 = allStrips.filter(hasFillableBlanks)
    val conformantStrips2 = conformantStrips1.filter(stripIsDisconnectedInLine)
    conformantStrips2
  }

  def stripIsDisconnectedInLine(strip: Strip): Boolean = {
    val firstPoint = strip.point(0)
    val lastPoint = strip.point(strip.end - strip.begin)
    val maybePrevPiece = prev(firstPoint, strip.axis)
    val maybeNextPiece = next(lastPoint, strip.axis)

    def isSeparator(maybeBlackWhitePiece: Option[BlackWhite[Piece]]): Boolean = {
      maybeBlackWhitePiece match {
        case None => true
        case Some(bwPiece) =>
          bwPiece match {
            case Black() => true
            case White(None) => true
            case White(Some(_)) => false
          }
      }
    }
    isSeparator(maybePrevPiece) && isSeparator(maybeNextPiece)
  }

  def computeAllLiveStrips : List[Strip] = grid.allSegments map lineSegmentToStrip

  def enclosingStripsOfBlankPoints(axis: Axis): Map[Point, List[Strip]] = {
    val stripsEnclosingBlanks = (grid.segmentsAlongAxis(axis) map lineSegmentToStrip) filter { _.numBlanks > 0 }
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
  def apply(dimension: Int, cellMaker: Int => Int => BlackWhite[Piece]) : Board = {
    val grid = BlackWhiteGrid[Piece](cellMaker, dimension, dimension)
    Board(dimension, grid)
  }

  def apply(dimension: Int) : Board = {
    def cellMaker(row: Int)(col: Int): BlackWhite[Piece] = White(None)
    val grid = BlackWhiteGrid[Piece](cellMaker _, dimension, dimension)
    Board(dimension, grid)
  }

  /**
    * Create a board with the given pieces at the given positions in the grid pieces.
    */
  def apply(dimension: Int, gridPieces: List[GridPiece]): Board = {
    def maybeGridPiece(r: Int, c: Int) = gridPieces.find(_.point == Point(r, c))
    def cellMaker(row: Int)(col: Int): BlackWhite[Piece] = {
      maybeGridPiece(row, col) match {
        case Some(GridPiece(piece, point)) => White(Some(piece))
        case None => White(None)
      }
    }
    Board(dimension, cellMaker _)
  }

  def lineSegmentToStrip(lineSegment: LineSegment[Piece]): Strip = {
    def optToChar(opt: Option[Piece]): Char =
      opt match {
        case None => ' '
        case Some(piece) => piece.value
      }

    lineSegment match {
      case LineSegment(axis, lineNumber, begin, end, segment) =>
        Strip(axis, lineNumber, begin, end, (segment map optToChar).mkString)
    }
  }
}

