/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.PlayerType.{MachinePlayer, playerIndex}
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.Piece.isBlank
import com.bolour.boardgame.scala.server.domain.GameExceptions.InternalGameException
import com.bolour.boardgame.scala.server.domain.Strip.GroupedStrips
import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.boardgame.scala.server.util.WordUtil.{DictWord, Length, LetterCombo, NumBlanks}
import org.slf4j.LoggerFactory

import scala.collection.mutable

trait StripMatcher {
  // abstract members
  def dictionary: WordDictionary
  def board: Board
  def tray: Tray
  // end abstract

  import StripMatcher._

  val logger = LoggerFactory.getLogger(this.getClass)

  val dimension = board.dimension
  val grid = board.grid
  val trayLetters = tray.pieces.map(_.value).mkString
  val trayCombosByLength = WordUtil.computeCombosGroupedByLength(trayLetters)
  val playableStrips = computePlayableStrips

  // def bestMatch(): StripMatch = bestMatchUpToLength(dimension)

  def bestMatch(): List[PlayPiece] = {
    bestMatchUpToLength(dimension) match {
      case None => Nil
      case Some((strip, word)) => matchedStripPlayPieces(strip, word)
    }
  }

  def matchedStripPlayPieces(strip: Strip, word: String): List[PlayPiece] = {
    // Buffer used to peel off played letters from tray pieces - leaving tray immutable.
    val restTrayPieces: mutable.Buffer[Piece] = tray.pieces.toBuffer

    def removeTrayChar(letter: Char) = {
      restTrayPieces.remove(restTrayPieces.indexWhere(_.value == letter))
    }

    def toPlayPiece(stripOffset: Int) = {
      val point = strip.point(stripOffset)
      val stripLetter = strip.content(stripOffset)
      val wordLetter = word(stripOffset)
      val moved = isBlank(stripLetter)
      val piece = if (moved) removeTrayChar(wordLetter) else board.get(point)
      PlayPiece(piece, point, moved)
    }

    val stripOffsets = (0 until strip.content.length).toList
    stripOffsets.map(offset => toPlayPiece(offset))
  }


  def bestMatchUpToLength(limit: Length): StripMatch = {
    if (limit <= 1)
      return None
    limit match {
      case 2 => bestMatchForLength(2)
      case _ => bestMatchForLength(limit) orElse
        bestMatchUpToLength(limit - 1)
    }
  }

  val EMPTY = true
  val NON_EMPTY = false

  def bestMatchForLength(len: Length): StripMatch = {
    if (board.isEmpty)
      return bestMatchForLengthOnEmptyBoard(len)

    for /* option */ {
      stripsByBlanks <- playableStrips.get(len)
      optimal <- bestMatchForStrips(stripsByBlanks)
    } yield optimal
  }

  /**
    * First match on empty board is special - no anchor.
    * For the first play we use an all-blank center strip of the given length.
    */
  def bestMatchForLengthOnEmptyBoard(len: Length): StripMatch = {
    for /* option */ {
      combos <- trayCombosByLength.get(len)
      // _ = println(combos)
      optimal <- bestMatchForStrip(emptyCenterStrip(len), combos)
    } yield optimal
  }

  private def emptyCenterStrip(len: Length) = {
    val center = dimension / 2
    val mid = len / 2
    val content = List.fill(len)(' ').mkString
    val strip = Strip(Axis.X, center, center - mid, center + (len - mid) - 1, content)
    strip
  }

  /**
    * Find the best match for all strips of a given length - they are indexed by the
    * number of blank slots. TODO. Should length be a parameter?
    */
  def bestMatchForStrips(stripsByBlanks: Map[NumBlanks, List[Strip]]): StripMatch = {

    /*
     * For each set of strips with a given number of blanks, get the
     * corresponding combos of tray letters that would fill their blanks exactly.
     * The result is a list of (numBlanks, List[Strip], List[LetterCombo]).
     * Sort that list in descending order on the number of blanks -
     * making it possible to prioritize matches by the number of filled blanks.
     */
    val groupedStripsAndCombos = stripsByBlanks.toList.map {
      case (blanks, strips) => (blanks, strips, trayCombosByLength(blanks))
    }
    val sortedGroups = groupedStripsAndCombos.sortWith(_._1 > _._1)
    bestMatchForStripsAndCombosGroupedByBlanks(sortedGroups)
  }

  /**
    * Find the best match for corresponding strips and tray combos
    * grouped by the number of blanks in strips and equivalently by the
    * length of combos in tray, so that the tray combos may exactly
    * fill in the blanks of the corresponding strips.
    *
    * The groups are ordered in decreasing order of the number of blanks.
    * The first match found in that order is returned - otherwise recurse.
    */
  private def bestMatchForStripsAndCombosGroupedByBlanks(
    groupedStripsAndCombos: List[(NumBlanks, List[Strip], List[LetterCombo])]): StripMatch =
    groupedStripsAndCombos match {
      case Nil => None
      case (blanks, strips, combos) :: groups =>
        val bestHeadMatch = bestMatchForCorrespondingStripsAndCombos(blanks, strips, combos)
        bestHeadMatch match {
          case Some(_) => bestHeadMatch
          case None => bestMatchForStripsAndCombosGroupedByBlanks(groups)
        }
    }

  /**
    * Find the best match given a set of strips and a set of tray combos
    * each of which can exactly fill in the blanks of each strip.
    *
    * @param blanks The number of blanks in each strip and the number
    *               of letters in each combo. // TODO. Unnecessary??
    * @param strips List of strips to try.
    * @param combos List of combos to try.
    */
  private def bestMatchForCorrespondingStripsAndCombos(
    blanks: NumBlanks, strips: List[Strip], combos: List[LetterCombo]): StripMatch =
    strips match {
      case Nil => None
      case strip :: rest =>
        val bestStripMatch = bestMatchForStrip(strip, combos)
        bestStripMatch match {
          case Some(_) => bestStripMatch
          case None => bestMatchForCorrespondingStripsAndCombos(blanks, rest, combos)
        }
    }

  /**
    * Given a list of tray letter combinations each of which can fill in
    * the blank slots of a strip exactly, find the best word match.
    */
  def bestMatchForStrip(strip: Strip, combos: List[LetterCombo]): StripMatch = {
    combos match {
      case Nil => None
      case combo :: restCombos =>
        val wordCombo = WordUtil.mergeLetterCombos(strip.letters, combo)
        val words = dictionary.permutedWords(wordCombo)
        // TODO. Find all fitting words and check each for crossword compliance.

        val fittingWords = strip.findFittingWords(words)
        val crossCheckedFittingWords = fittingWords.filter { word =>
          crossings(strip, word).forall(crossWord => dictionary hasWord crossWord)
        }

        // strip.findFittingWord(words) match {
        crossCheckedFittingWords.headOption match {
          case None => bestMatchForStrip(strip, restCombos)
          case Some(word) => Some((strip, word))
        }
    }
  }

  /**
    * A crossing is cross word that includes one of the new
    * letters played on a strip.
    *
    * All crossings must be legitimate words in the dictionary.
    */
  def crossings(strip: Strip, word: String): List[String] = {
    val l = word.length
    val range = (0 until l).toList
    val crossingIndices = range.filter {
      i =>
        val stripChar = strip.content(i)
        Piece.isBlank(stripChar)
    }
    val acrossWordList = crossingIndices.map{ i =>
      val point = strip.point(i)
      val playedChar = word(i)
      crossingChars(point, playedChar, Axis.crossAxis(strip.axis))
    }

    acrossWordList.filter {word => word.length > 1}
  }

  def crossingChars(crossPoint: Point, crossingChar: Char, axis: Axis): String = {
    val Point(row, col) = crossPoint

    /**
      * Given a point on the board, find the closest filled/empty boundary
      * in a given direction (considering the point as filled).
      *
      * @param point     The starting point.
      * @param axis      The axis along which to look for the next empty position.
      * @param direction The direction (+1, -1) to look along the axis.
      * @return The coordinate (row or column number) of the last contiguous
      *         filled position along the given direction.
      */
    def filledUpTo(point: Point, axis: Axis, direction: Int): Point = {

      // logger.info(s"filledUpTo - point ${point}, axis: ${axis}, direction: ${direction}")

      def free(maybePiece: Option[Piece]) =
        maybePiece.isEmpty || maybePiece.get.isEmpty

      def nextPiece(point: Point) =
        grid.adjacentCell(point, axis, direction).map(_.piece)

      def pointIsEmpty(point: Point): Boolean = {
        grid.cell(point).piece.isEmpty
      }

      def isBoundary(point: Point): Boolean = {
        val isFilled = !pointIsEmpty(point)
        val is = isFilled && free(nextPiece(point))
        // logger.info(s"point ${point} is filled? ${isFilled}, is boundary? ${is}")
        is
      }

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

    val beforeBoundary = filledUpTo(crossPoint, axis, -1)
    val afterBoundary = filledUpTo(crossPoint, axis, +1)
    val crossCharSeq = axis match {
      case Axis.X =>
        def crossChar(i: Int) = grid.cell(Point(row, i)).piece.value
        val beforeChars = (beforeBoundary.col to col - 1).map(i => crossChar(i))
        val afterChars = (col + 1 to afterBoundary.col).map(i => crossChar(i))
        beforeChars ++ List(crossingChar) ++ afterChars
      case Axis.Y =>
        def crossChar(i: Int) = grid.cell(Point(i, col)).piece.value
        val beforeChars = (beforeBoundary.row to row - 1).map(i => crossChar(i))
        val afterChars = (row + 1 to afterBoundary.row).map(i => crossChar(i))
        beforeChars ++ List(crossingChar) ++ afterChars
    }

    crossCharSeq.mkString
  }

  def computePlayableStrips: GroupedStrips = {
    if (board.isEmpty) computePlayableStripsForEmptyBoard
    else computePlayableStripsForNonEmptyBoard
  }

  def computePlayableStripsForEmptyBoard: GroupedStrips = {
    val center = dimension/2
    val centerRow = board.rows(center)
    val centerRowAsString = Piece.piecesToString(centerRow.map(_.piece)) // converts null chars to blanks
    val strips = Strip.stripsInLine(Axis.X, dimension, center, centerRowAsString)
    val conformantStrips = strips.filter { strip => strip.begin <= center && strip.end >= center}
    // TODO. Factor out grouping here and from computePlayableStrips.
    val conformantStripsByLength = conformantStrips.groupBy(_.content.length)
    conformantStripsByLength.mapValues(_.groupBy(_.numBlanks))
  }

  def computePlayableStripsForNonEmptyBoard: GroupedStrips = {
    val traySize = tray.pieces.length
    val allStrips = computeAllStrips
    def hasFillableBlanks = (s: Strip) => s.numBlanks > 0 && s.numBlanks <= traySize
    val conformantStrips1 = allStrips.filter(hasFillableBlanks)
    val conformantStrips2 = conformantStrips1.filter(_.hasAnchor)
    val conformantStrips3 = conformantStrips2.filter(isDisconnectedInLine)
    val conformantStripsByLength = conformantStrips3.groupBy(_.content.length)
    conformantStripsByLength.mapValues(_.groupBy(_.numBlanks))
  }

  def isDisconnectedInLine(strip: Strip): Boolean = {
    val firstPoint = strip.point(0)
    val lastPoint = strip.point(strip.end - strip.begin)
    val maybePrevPiece = grid.prevCell(firstPoint, strip.axis).map {_.value}
    val maybeNextPiece = grid.nextCell(lastPoint, strip.axis).map {_.value}
    def isSeparator(maybePiece: Option[Piece]): Boolean = {
      maybePiece match {
        case None => true
        case Some(piece) => piece.isEmpty
      }
    }
    isSeparator(maybePrevPiece) && isSeparator(maybeNextPiece)
  }

  def computeAllStrips: List[Strip] = {
    def charsOfLine = (line: List[GridPiece]) => Piece.piecesToString(line.map(_.value))
    def rows: List[String] = board.rows.map(charsOfLine)
    def columns: List[String] = board.columns.map(charsOfLine)
    val xStrips = Strip.allStrips(Axis.X, dimension, rows)
    val yStrips = Strip.allStrips(Axis.Y, dimension, columns)
    xStrips ++ yStrips
  }
}

object StripMatcher {
  type StripMatch = Option[(Strip, DictWord)]
}