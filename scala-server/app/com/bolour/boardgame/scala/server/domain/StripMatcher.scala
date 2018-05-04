/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import org.slf4j.LoggerFactory

import scala.collection.immutable.Nil
import scala.collection.mutable
// import com.bolour.boardgame.scala.common.domain.Piece.isBlank
import com.bolour.boardgame.scala.common.domain._
import com.bolour.language.scala.domain.WordDictionary
import com.bolour.plane.scala.domain.Axis.Axis
import com.bolour.plane.scala.domain.{Axis, Point}
import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.boardgame.scala.server.util.WordUtil.{DictWord, LetterCombo, NumBlanks}

/**
  * StripMatcher finds the best word match to a given board.
  *
  * A match is the tuple (word, strip) where the word exists in the
  * dictionary and can legally be played onto the strip: that is,
  * the blanks of the strip can be filled by letters in the tray,
  * and all crosswords formed by playing the word exist in
  * the dictionary.
  *
  * The algorithm first groups the strips of the board by the "value"
  * of a play on them. The value of a strip is a positive integer
  * that reflects the expected added score by playing a word on that strip.
  * So the algorithm checks for matches in decreasing order of strip value,
  * stopping as soon as a match is found.
  *
  * The naive valuation used here initially simply uses the number of
  * blank characters within the strip, in the hope that in general
  * the more characters played to form a word the higher the score.
  * For now, this naive valuation scheme works reasonably well.
  * To experiment with different valuation schemes, sub-class this
  * trait and override the "stripValuation" function.
  *
  * Additionally within each group of equally-valued strips, the strips
  * of the group are further grouped by the number of blanks appearing
  * in each. Then for each sub-group of a given blank-count,
  * all combinations of tray letters of size blank-count are
  * tried against all strips of the sub-group.
  */
trait StripMatcher {
  // abstract members
  def dictionary: WordDictionary
  def board: Board
  def tray: Tray
  // end abstract

  import StripMatcher._

  protected[this] val logger = LoggerFactory.getLogger(this.getClass)

  protected[this] val dimension = board.dimension
  protected[this] val trayLetters = tray.pieces.map(_.value).mkString
  protected[this] val trayCombosByLength = WordUtil.computeCombosGroupedByLength(trayLetters)
  // TODO. Improve strip valuation by summing the point values of its blanks.
  protected[this] val stripValuation: Strip => StripValue = _.numBlanks
  protected[this] val playableStripsGroupedByValueAndBlanks: Map[StripValue, Map[NumBlanks, List[Strip]]] =
    groupPlayableStrips(stripValuation)
  protected[this] val allValues = playableStripsGroupedByValueAndBlanks.keySet
  protected[this] val maxStripValue = if (allValues.isEmpty) 0 else allValues.max
  protected[this] val crossWordFinder = new CrossWordFinder(board)

  /**
    * Main entry point - find the best match if any (empty list means none found).
    */
  def bestMatch(): List[PlayPiece] = {
    bestMatchUpToValue(maxStripValue) match {
      case None => Nil
      case Some((strip, word)) => matchedStripPlayPieces(strip, word)
    }
  }

  /**
    * A match is represented internally as the tuple (strip, word)
    * meaning the word matches (and is to be played on) the strip -
    * convert the match to a list of play pieces (needed by clients).
    */
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
      val moved = WordUtil.isBlankChar(stripLetter)
      val piece = if (moved) removeTrayChar(wordLetter) else board.getPiece(point).get
      PlayPiece(piece, point, moved)
    }

    val stripOffsets = (0 until strip.content.length).toList
    stripOffsets.map(offset => toPlayPiece(offset))
  }

  /**
    * Find the best word match on the board among all matches whose
    * values are less than or equal to a given value.
    */
  def bestMatchUpToValue(maxValue: StripValue): StripMatch = {
    if (maxValue <= 0)
      return None
    findMatchForValue(maxValue) orElse bestMatchUpToValue(maxValue - 1)
  }

  def findMatchForValue(value: StripValue): StripMatch = {
    // TODO. Try not to special-case empty board here. Only in getting playable strips.
    if (board.isEmpty)
      return findMatchForValueOnEmptyBoard(value)

    for /* option */ {
      stripsByBlanks <- playableStripsGroupedByValueAndBlanks.get(value)
      optimal <- findMatchForStrips(stripsByBlanks)
    } yield optimal
  }

  /**
    * First match on empty board is special - no anchor.
    * For the first play we use an all-blank center strip of the given length.
    */
  def findMatchForValueOnEmptyBoard(len: StripValue): StripMatch = {
    for /* option */ {
      combos <- trayCombosByLength.get(len)
      // _ = println(combos)
      optimal <- findMatchForStrip(emptyCenterStrip(len), combos)
    } yield optimal
  }

  private def emptyCenterStrip(len: StripValue) = {
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
  def findMatchForStrips(stripsByBlanks: Map[NumBlanks, List[Strip]]): StripMatch = {

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
    findMatchForStripsAndCombosGroupedByBlanks(sortedGroups)
  }

  /**
    * Find a match for corresponding strips and tray combos
    * grouped by the number of blanks in strips and equivalently by the
    * length of combos in tray, so that the tray combos may exactly
    * fill in the blanks of the corresponding strips.
    *
    * The groups are ordered in decreasing order of the number of blanks.
    * The first match found in that order is returned - otherwise recurse.
    */
  private def findMatchForStripsAndCombosGroupedByBlanks(
    groupedStripsAndCombos: List[(NumBlanks, List[Strip], List[LetterCombo])]): StripMatch =
    groupedStripsAndCombos match {
      case Nil => None
      case (blanks, strips, combos) :: groups =>
        val headMatch = findMatchForCorrespondingStripsAndCombos(blanks, strips, combos)
        headMatch match {
          case Some(_) => headMatch
          case None => findMatchForStripsAndCombosGroupedByBlanks(groups)
        }
    }

  /**
    * Find a match for a set of strips and a set of tray combos
    * each of which can exactly fill in the blanks of each of the strips.
    *
    * @param blanks The number of blanks in each strip and the number
    *               of letters in each combo. // TODO. Unnecessary??
    * @param strips List of strips to try.
    * @param combos List of combos to try.
    */
  private def findMatchForCorrespondingStripsAndCombos(
    blanks: NumBlanks, strips: List[Strip], combos: List[LetterCombo]): StripMatch =
    strips match {
      case Nil => None
      case strip :: rest =>
        val bestStripMatch = findMatchForStrip(strip, combos)
        bestStripMatch match {
          case Some(_) => bestStripMatch
          case None => findMatchForCorrespondingStripsAndCombos(blanks, rest, combos)
        }
    }

  /**
    * Given a list of tray letter combinations each of which can fill in
    * the blank slots of a strip exactly, find a combination that when
    * played on the strip produces a legal play.
    */
  def findMatchForStrip(strip: Strip, combos: List[LetterCombo]): StripMatch = {
    combos match {
      case Nil => None
      case combo :: restCombos =>
        val wordCombo = WordUtil.mergeLetterCombos(strip.letters, combo)
        val words = dictionary.permutations(wordCombo)
        // TODO. Find all fitting words and check each for crossword compliance.

        val fittingWords = strip.findFittingWords(words)
        val crossCheckedFittingWords = fittingWords.filter { word =>
          crossWordFinder.findStripCrossWords(strip, word).forall(crossWord => dictionary hasWord crossWord)
        }

        // strip.findFittingWord(words) match {
        crossCheckedFittingWords.headOption match {
          case None => findMatchForStrip(strip, restCombos)
          case Some(word) => Some((strip, word))
        }
    }
  }

  def crossings(strip: Strip, word: String): List[String] =
    crossWordFinder.findStripCrossWords(strip, word)

  def groupPlayableStrips(valuation: Strip => Int): Map[StripValue, Map[NumBlanks, List[Strip]]] = {
    val conformantStrips = if (board.isEmpty)
      board.playableEmptyStrips(tray.pieces.length)
    else board.playableStrips(tray.pieces.length)

    val stripsByValue = conformantStrips.groupBy(valuation)
    stripsByValue.mapValues(_.groupBy(_.numBlanks))
  }

}

object StripMatcher {

  /**
    * The integer "value" associated with each strip.
    * Optimality is based on this value.
    *
    * Values start at 1 - and 0 is the basis of recursion
    * for decreasing values.
    */
  type StripValue = Int

  /**
    * A possible match found on a strip - if exists include
    * the strip and the matching word.
    */
  type StripMatch = Option[(Strip, DictWord)]

  private def findDenselyEnclosedBlanks(board: Board, maxBlanks: Int, axis: Axis) = {
    def allDense(strips: List[Strip]) = strips forall { _.isDense(maxBlanks) }

    val blanksToStrips = board.playableEnclosingStripsOfBlankPoints(axis)
    blanksToStrips filter { case (_, strips) => allDense(strips)}
  }

  def findAndSetBoardBlackPoints(dictionary: WordDictionary)(board: Board): (Board, List[Point]) = {
    val directDeadPoints = StripMatcher.findBlackPoints(board, dictionary).toList
    val newBoard = board.setBlackPoints(directDeadPoints)
    directDeadPoints match {
      case Nil => (newBoard, directDeadPoints)
      case _ =>
        val (b, moreDeadPoints) = findAndSetBoardBlackPoints(dictionary)(newBoard)
        val allDeadPoints = directDeadPoints ++ moreDeadPoints
        (b, allDeadPoints)
    }
  }


  val Caps = 'A' to 'Z'

  /**
    * Find blank point that can never be covered.
    *
    * The algorithm uses a precomputed set of masked words. A masked word
    * is a word some of whose letters have been changed to blanks. If a strip
    * is at all playable, then its content as a masked word must exist in the
    * masked words index. However, we do not store all masked versions of
    * a word: only those that are "dense", that is, those that only have a few
    * blanks.
    *
    * The dictionary contains all masked words with up to maxMaskedWords blanks.
    * We find the points that are covered only by dense strips of at most maxMaskedWords + 1 blanks.
    * Then we try all letters from A to Z on each such point. The resulting strips covering
    * that point now have maxMaskedWords blanks, and their content can be looked up
    * as masked words in the dictionary.
    */
  def findBlackPoints(board: Board, dictionary: WordDictionary): Set[Point] = {

    val maxBlanks = dictionary.maxMaskedLetters + 1

    val hEnclosures: Map[Point, List[Strip]] =
      findDenselyEnclosedBlanks(board, maxBlanks, Axis.X)

    val vEnclosures: Map[Point, List[Strip]] =
      findDenselyEnclosedBlanks(board, maxBlanks, Axis.Y)

    val points = hEnclosures.keySet ++ vEnclosures.keySet

    def stripListForPoint(point: Point): List[(Axis, List[Strip])] = {
      val hStrips: List[Strip] = hEnclosures.getOrElse(point, Nil)
      val vStrips: List[Strip] = vEnclosures.getOrElse(point, Nil)
      List((Axis.X, hStrips), (Axis.Y, vStrips))
    }

    points filter { point =>
      val stripList = stripListForPoint(point)
      Caps forall { ch => noMatchInStripsForPoint(board, dictionary, point, ch, stripList)}
    }
  }

  type Anchored = Boolean
  type MaskedStripContentExists = Boolean

  /**
    * For a blank point that is covered only by dense strips in some direction (X or Y),
    * determine if the given letter were played to that point, no word would match it.
    *
    * @param board The existing board.
    * @param dictionary The word dictionary.
    * @param point The point.
    * @param letter The desired letter to cover the point.
    * @param enclosingDenseStrips
    *        A list of two 2-tuples, one each for the X and Y axis,
    *        each providing the list of dense strips covering the point.
    *        If the strip list is empty, some non-dense strip in the given
    *        direction may cover the point. If the strip list is non-empty,
    *        we know that only the given strips, all of which are dense,
    *        cover the strip in that direction.
    * @return True if we know for sure that no word will can be played that
    *         covers the given point with the given letter.
    */
  def noMatchInStripsForPoint(board: Board, dictionary: WordDictionary,
    point: Point, letter: Char, enclosingDenseStrips: List[(Axis, List[Strip])]): Boolean = {

    val statuses: List[(Anchored, MaskedStripContentExists)] =
      enclosingDenseStrips map {
        case (axis, strips) =>
          val anchored = board.hasRealNeighbor(point, axis)
          val filledContents = strips map { _.fillBlankInStrip(point, letter) }

          // If the point has no dense enclosing strips, for all we know some non-dense
          // strip can cover it. So pretend that it is covered by a match.
          val filledContentExists = filledContents match {
            case Nil => true
            case _ => filledContents exists dictionary.hasMaskedWord
          }

          (anchored, filledContentExists)
      }

    val (anchored1, exists1) = statuses(0)
    val (anchored2, exists2) = statuses(1)

    !exists1 && !exists2 || !exists1 && anchored1 || !exists2 && anchored2
  }

}
