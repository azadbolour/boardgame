/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import org.slf4j.LoggerFactory
import scala.collection.mutable
import com.bolour.boardgame.scala.common.domain.Piece.isBlank
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
  * and all crosswords formed by the playing the word exist in
  * the dictionary.
  *
  * The algorithm first groups the strips of the board by the "value"
  * of a play on them. The value of a strip is supposed to be reflective of the
  * expected added score by playing a word on that strip. So the
  * algorithm checks for matches in decreasing order of strip value,
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

  /** Main entry point - find the best match if any (empty list means none found). */
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
      val moved = isBlank(stripLetter)
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
    if (maxValue <= 1)
      return None
    maxValue match {
      case 2 => findMatchForValue(2) // TODO. Special-casing not needed.
      case _ => findMatchForValue(maxValue) orElse
        bestMatchUpToValue(maxValue - 1)
    }
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
  /** Values start at 1 - so 0 is the basis of recursion for decreasing values. */
  type StripValue = Int
  type StripMatch = Option[(Strip, DictWord)]


  /**
    * Attempt to find blank points that cannot possibly be filled.
    *
    * The algorithm uses a precomputed set of masked words. A masked word
    * is a word some of whose letters have been changed to blanks. If a strip
    * is at all playable, then its content as a masked word must exist in the
    * masked words index. However, we do not store all masked versions of
    * a word: only those that are "dense", that is, those that only have a few
    * blanks.
    *
    * The algorithm works by finding those blank points that can only
    * be covered by making a play on a "dense" strip. A dense strip
    * is one that only has a few blanks. Once we know
    * that a blank point is only coverable by dense strip plays, we can
    * look up the contents of each of its covering dense strips in the
    * masked word index, and if none of them exists, we know that the blank
    * is hopeless.
    *
    * This algorithm, of course, will miss some hopeless blanks. But detecting
    * hopeless blanks is most useful when the board is densely populated,
    * increasing the possibility of finding blanks that are only coverable
    * by dense strips.
    *
    * @param axis Axis along which to check for matching words.
    * @return List of hopeless blank points.
    */
  def hopelessBlankPointsForAxis(board: Board, dictionary: WordDictionary, trayCapacity: Int, axis: Axis): Set[Point] = {
    // val blanksToStrips = board.potentialPlayableStripsForBlanks(axis, trayCapacity)

    val blanksToStrips = board.playableEnclosingStripsOfBlankPoints(axis, trayCapacity)
    val maxStripBlanks = dictionary.maxMaskedLetters

    def allDense(strips: List[Strip]) =
      strips forall {_.isDense(maxStripBlanks)}
    val denselyEnclosedBlanks =
      blanksToStrips filter { case (_, strips) => allDense(strips) }

    def stripMatchExists(strips: List[Strip]) =
      strips exists { s => dictionary.hasMaskedWord(s.content)}
    val stripsForHopelessBlanks =
      denselyEnclosedBlanks filter { case (_, strips) => !stripMatchExists(strips)}

    stripsForHopelessBlanks.keySet
  }

  /**
    * Get heuristically detected hopeless blank points.
    * First get hopeless blank for each axis (independently of the other).
    * Split each into two sets based on whether the blank point has an adjacent anchor.
    * Blank points that have an adjacent anchor are definitely out independently of the other axis.
    * Those that do not must have a match on one axis, hence intersect.
    */
  def hopelessBlankPoints(board: Board, dictionary: WordDictionary, trayCapacity: Int): Set[Point] = {
    val forX = hopelessBlankPointsForAxis(board, dictionary, trayCapacity, Axis.X)
    val (anchoredX, freeX) = forX partition { pt => board.hasRealNeighbor(pt, Axis.X)}

    val forY = hopelessBlankPointsForAxis(board, dictionary, trayCapacity, Axis.Y)
    val (anchoredY, freeY) = forY partition { pt => board.hasRealNeighbor(pt, Axis.Y)}

    anchoredX ++ anchoredY ++ (freeX intersect freeY)
  }

}
