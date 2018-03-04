package com.bolour.boardgame.scala.server.domain

import com.bolour.util.scala.common.CommonUtil
import com.bolour.plane.scala.domain.Axis.Axis
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
    CommonUtil.catOptions(acrossWordList)
  }

  /**
    * Not used for now but is needed when scores of cross plays figure in the total score.
    */
  def findCrossPlays(playPieces: List[PlayPiece]): List[List[(Char, Point, Boolean)]] = {
    val strip = board.stripOfPlay(playPieces)
    val word = PlayPieceObj.playPiecesToWord(playPieces)
    findCrossPlays(strip, word)
  }

  def findCrossPlays(strip: Strip, word: String): List[List[(Char, Point, Boolean)]] = {
    val l = word.length
    val range = (0 until l).toList
    val crossingIndices = range.filter { i => Piece.isBlank(strip.content(i)) }
    val crossPlayOpts = crossingIndices map { i =>
      val point = strip.point(i)
      crossingPlay(point, word(i), Axis.crossAxis(strip.axis))
    }
    CommonUtil.catOptions(crossPlayOpts)
  }

  def findCrossingWord(crossPoint: Point, crossingChar: Char, axis: Axis): Option[String] = {
    val optCrossPlay: Option[List[(Char, Point, Boolean)]] = crossingPlay(crossPoint, crossingChar, axis)
    optCrossPlay map { play => (play map { case (char, _, _) => char } ).mkString}
    // val word = (play map { case (char, _, _) => char } ).mkString
    // word
  }

  // TODO. Too much going on within this function. Make it more readable as in Haskell server.
  /**
    * Get information about a particular crossword created as a result of
    * playing a letter on a point.
    * @param crossPoint The point at which the letter is played.
    * @param crossingChar The letter played at that point.
    * @param crossAxis The cross axis along which the crossword lies.
    *
    * @return List of tuples (char, point, moved) for the crossword
    *         providing information about the crossword. Each tuple
    *         includes a letter of the crossword, its location on the board,
    *         and whether the letter is being played. The only letter that
    *         is being moved is the one at the cross point. All others
    *         exist on the board. Return None is there is no cross word at the given point.
    */
  def crossingPlay(crossPoint: Point, crossingChar: Char, crossAxis: Axis): Option[List[(Char, Point, Boolean)]] = {
    def toMoveInfo(piecePoint: PiecePoint) = piecePoint match {
      case PiecePoint(piece, point) => (piece.value, point, false)
    }

    val forthNeighborsInfo = board.lineNeighbors(crossPoint, crossAxis, Axis.forward) map toMoveInfo
    val backNeighborsInfo = board.lineNeighbors(crossPoint, crossAxis, Axis.backward) map toMoveInfo

    val crossingMoveInfo = (crossingChar, crossPoint, true)

    if (forthNeighborsInfo.isEmpty && backNeighborsInfo.isEmpty)
      return None
    Some (backNeighborsInfo ++ List(crossingMoveInfo) ++ forthNeighborsInfo)
  }

}
