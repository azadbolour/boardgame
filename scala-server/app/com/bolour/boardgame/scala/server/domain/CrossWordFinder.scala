package com.bolour.boardgame.scala.server.domain

import com.bolour.plane.scala.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.PlayPieceObj.PlayPieces
import com.bolour.boardgame.scala.common.domain._
import com.bolour.plane.scala.domain.{Axis, Point}

class CrossWordFinder(board: Board) {
  val dimension = board.dimension
  val grid = board.grid

  // TODO. Move direction constants to a utility object.
  // TODO. Use direction constants.
  val ForwardDir = 1
  val BackwardDir = -1

  /**
    * Considering a point to be a neighbor if it is recursively adjacent to
    * the given point in the given direction, find the farthest one in that direction.
    * This is a helper method for finding surrounding plays and words.
    *
    * @param point The point whose farthest neighbor is being sought.
    * @param axis The axis along which we are looking for the neighbor.
    * @param direction The direction along the axis to look.
    * @return The farthest (recursive) neighbor.
    */
  private def farthestNeighbor(point: Point, axis: Axis, direction: Int): Point = {

    def outOfBoundsOrEmpty(oPoint: Option[Point]): Boolean =
      oPoint.isEmpty || board.pointIsEmpty(oPoint.get)

    def adjacent(p: Point): Option[Point] = board.nthNeighbor(p, axis, direction)(1)

    def isBoundary(p: Point): Boolean =
      !board.pointIsEmpty(p) && outOfBoundsOrEmpty(adjacent(p))

    // The starting point is special because it is empty.
    if (outOfBoundsOrEmpty(adjacent(point)))
      return point

    val neighbors = (1 until dimension).toList map board.nthNeighbor(point, axis, direction)
    val farthest = neighbors find (_.exists(isBoundary))
    farthest.get.get // A boundary always exists.
  }

  /**
    * A crossing is cross word that includes one of the new
    * letters played on a strip.
    *
    * All crossings must be legitimate words in the dictionary.
    */
  def findStripCrossWords(strip: Strip, word: String): List[String] = {
    val l = word.length
    val range = (0 until l).toList
    val crossingIndices = range.filter { i => Piece.isBlank(strip.content(i)) }
    val acrossWordList = crossingIndices.map{ i =>
      val point = strip.point(i)
      val playedChar = word(i)
      findCrossingWord(point, playedChar, Axis.crossAxis(strip.axis))
    }

    acrossWordList.filter {word => word.length > 1}
  }

  def findCrossPlays(playPieces: List[PlayPiece]): List[List[(Char, Point, Boolean)]] = {
    val strip = board.stripOfPlay(playPieces)
    val word = PlayPieceObj.playPiecesToWord(playPieces)
    findCrossPlays(strip, word)
  }

  def findCrossPlays(strip: Strip, word: String): List[List[(Char, Point, Boolean)]] = {
    val l = word.length
    val range = (0 until l).toList
    val crossingIndices = range.filter { i => Piece.isBlank(strip.content(i)) }
    val plays = crossingIndices map { i =>
      val point = strip.point(i)
      crossingPlay(point, word(i), Axis.crossAxis(strip.axis))
    }
    plays
  }

  def findCrossingWord(crossPoint: Point, crossingChar: Char, axis: Axis): String = {
    val play: List[(Char, Point, Boolean)] = crossingPlay(crossPoint, crossingChar, axis)
    val word = (play map { case (char, _, _) => char } ).mkString
    word
  }

  // TODO. Too much going on within this function. Make it more readable as in Haskell server.
  /**
    * Get information about a particular crossword created as a result of
    * playing a letter on a point.
    * @param crossPoint The point at which the letter is played.
    * @param crossingChar The letter played at that point.
    * @param axis The cross axis along which the crossword lies.
    *
    * @return List of tuples (char, point, moved) for the crossword
    *         providing information about the crossword. Each tuple
    *         includes a letter of the crossword, its location on the board,
    *         and whether the letter is being played. The only letter that
    *         is being moved is the one at the cross point. All others
    *         exist on the board.
    */
  def crossingPlay(crossPoint: Point, crossingChar: Char, axis: Axis): List[(Char, Point, Boolean)] = {
    val Point(row, col) = crossPoint

    // Auxiliary functions.

    def boardPointInfo(p: Point): (Char, Point, Boolean) = {
      val piece = board.getPiece(p)
      val info = (piece.value, p, false) // Filled position across play direction cannot have moved.
      info
    }

    val Point(beforeRow, beforeCol) = farthestNeighbor(crossPoint, axis, -1)
    val Point(afterRow, afterCol) = farthestNeighbor(crossPoint, axis, +1)

    def crossPlayPoint(i: Int): Point = axis match {
      case Axis.X => Point(row, i)
      case Axis.Y => Point(i, col)
    }
    def crossPlayInfo(i: Int): (Char, Point, Boolean) =
      boardPointInfo(crossPlayPoint(i))

    val (beforeInfo, afterInfo) = axis match {
      case Axis.X => (
        (beforeCol until col).map { crossPlayInfo(_) },
        (col + 1 to afterCol).map { crossPlayInfo(_)}
      )
      case Axis.Y => (
        (beforeRow until row).map { crossPlayInfo(_) },
        (row + 1 to afterRow).map { crossPlayInfo(_) }
      )
    }

    val crossingInfo = (crossingChar, crossPoint, true)
    val crossInfoSeq = beforeInfo ++ List(crossingInfo) ++ afterInfo

    crossInfoSeq.toList
  }

}
