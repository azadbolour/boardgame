package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.PlayPieceObj.PlayPieces
import com.bolour.boardgame.scala.common.domain._

class CrossWordFinder(board: Board) {
  val dimension = board.dimension
  val grid = board.grid

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

    /**
      * Given a point on the board, find the closest filled/empty boundary
      * in the direction of the cross axis (considering the point itself
      * as if it were filled).
      *
      * Used to find the extent of a crossword in each direction.
      *
      * @param point     The starting point.
      * @param direction The direction (+1, -1) to look along the axis.
      * @return The coordinate (row or column number) of the last contiguous
      *         filled position along the given direction.
      */
    def filledUpTo(point: Point, direction: Int): Point = {

      // logger.info(s"filledUpTo - point ${point}, axis: ${axis}, direction: ${direction}")

      def hasNoLetter(op: Option[Piece]) = op.isEmpty || op.get.isEmpty

      def nextPiece(p: Point) = grid.adjacentCell(p, axis, direction).map(_.piece)

      def pointIsEmpty(p: Point): Boolean = grid.cell(p).piece.isEmpty

      def isBoundary(p: Point): Boolean = !pointIsEmpty(p) && hasNoLetter(nextPiece(p))

      def inBounds(point: Point): Boolean = {
        val Point(row, col) = point
        row >= 0 && row < dimension && col >= 0 && col < dimension
      }

      def crossPoint(i: Int): Point = {
        val offset = i * direction
        axis match {
          case Axis.X => Point(row, col + offset)
          case Axis.Y => Point(row + offset, col)
        }
      }

      // The starting point is special because it is empty.
      val crossPt1 = crossPoint(1)
      // logger.info(s"first cross point: ${crossPt1}")
      if (!inBounds(crossPt1) || pointIsEmpty(crossPt1))
        return point

      var lastPoint = point // Not strictly necessary. Being extra defensive.
      for (i <- 1 until dimension) {
        val pt = crossPoint(i)
        // logger.info(s"cross point for ${i} is ${pt}")

        // Begin defensive.
        // Redundant check. Boundary should be reached before cross point goes out of bounds.
        if (!inBounds(pt))
          return lastPoint
        lastPoint = pt
        // End defensive.

        if (isBoundary(pt))
          return pt
      }
      point // Should never be reached. Keep compiler happy.
    }

    def boardPointInfo(p: Point): (Char, Point, Boolean) = {
      val piece = board.get(p)
      val info = (piece.value, p, false) // Filled position across play direction cannot have moved.
      info
    }

    val Point(beforeRow, beforeCol) = filledUpTo(crossPoint, -1)
    val Point(afterRow, afterCol) = filledUpTo(crossPoint, +1)

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
