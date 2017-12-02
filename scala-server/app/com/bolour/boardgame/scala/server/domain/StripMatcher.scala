/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.PlayerType.{MachinePlayer, playerIndex}
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.Piece.{isBlank}
import com.bolour.boardgame.scala.server.domain.Strip.GroupedStrips
import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.boardgame.scala.server.util.WordUtil.{DictWord, Length, LetterCombo, NumBlanks}

import scala.collection.mutable

trait StripMatcher {
  // abstract members
  def dictionary: WordDictionary
  def board: Board
  def tray: Tray
  // end abstract

  import StripMatcher._

  val dimension = board.height
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
        strip.findFittingWord(words) match {
          case None => bestMatchForStrip(strip, restCombos)
          case Some(word) => Some((strip, word))
        }
    }
  }

  def computePlayableStrips: GroupedStrips = {
    val traySize = tray.pieces.length
    val allStrips = computeAllStrips
    def hasFillableBlanks = (s: Strip) => s.numBlanks > 0 && s.numBlanks <= traySize
    val conformantStrips1 = allStrips.filter(hasFillableBlanks)
    val conformantStrips2 = conformantStrips1.filter(_.hasAnchor)
    // TODO. Check strip is free crosswise.
    def isFreeCrossWise = (s: Strip) => true
    val conformantStrips3 = conformantStrips2.filter(isFreeCrossWise)
    val conformantStripsByLength = conformantStrips3.groupBy(_.content.length)
    conformantStripsByLength.mapValues(_.groupBy(_.numBlanks))
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