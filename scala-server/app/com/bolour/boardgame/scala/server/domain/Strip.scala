/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis._
import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.Point
import com.bolour.boardgame.scala.server.util.WordUtil.{BLANK, DictWord, Length, LetterCombo, NumBlanks, nonBlankLetterCombo}

case class Strip(
  axis: Axis,               // direction
  lineNumber: Int,          // index (row, col) of enclosing line
  begin: Int,               // start index of strip
  end: Int,                 // end index (inclusive) of strip
  content: String          // sequence of letters and blanks
) {

  /** combination of letters on strip (sorted - with dups) */
  val letters: LetterCombo = nonBlankLetterCombo(content)
  /** number of blank slots on strip */
  val numBlanks: Int = content.length - letters.length
  val len = end - begin + 1

  /**
    * Word can potentially be played to this strip.
    * They have the same length, and the non-blank slots
    * of the strip match the corresponding letter of the word.
    */
  def admits(word: String): Boolean = {
    (len == word.length) && fits(content, word)
  }

  def findFittingWords(words: List[DictWord]): List[DictWord] = {
    words.filter(admits)
  }

  def findFittingWord(words: List[DictWord]): Option[DictWord] =
    words.find(admits)

  def hasAnchor: Boolean = numBlanks < len

  def row(offset: Int): Int = axis match {
    case X => lineNumber
    case Y => begin + offset
  }

  def column(offset: Int): Int = axis match {
    case X => begin + offset
    case Y => lineNumber
  }

  def point(offset: Int) = Point(row(offset), column(offset))

  import Strip._

  // TODO. Use fold.
  /** it has already been established that the rest of the word has the same length
    * as the rest of the strip content - so just compare their corresponding letters */
  private def fits(restContent: String, restWord: String): Boolean =
    if (restWord.isEmpty) true
    else fitsSlot(restContent.head, restWord.head) &&
           fits(restContent.tail, restWord.tail)
}

object Strip {
  type GroupedStrips = Map[Length, Map[NumBlanks, List[Strip]]]

  def apply(axis: Axis, lineNumber: Int, line: String, begin: Int, end: Int): Strip = {
    val content = line.slice(begin, end + 1)
    Strip(
      axis,
      lineNumber,
      begin,
      end,
      content
    )
  }

  def fitsSlot(slotLetter: Char, wordLetter: Char): Boolean =
    slotLetter == ' ' || slotLetter == wordLetter

  def allStrips(axis: Axis, dimension: Int, lines: List[String]): List[Strip] = {
    for {
      lineNumber <- lines.indices.toList
      begin <- 0 until dimension
      end <- (begin + 1) until dimension
    } yield Strip(axis, lineNumber, lines(lineNumber), begin, end)
  }

}

