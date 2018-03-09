/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.util

import org.slf4j.LoggerFactory

import scala.collection.mutable
import scala.collection.mutable.HashSet

object WordUtil {
  val logger = LoggerFactory.getLogger(this.getClass)

  type Length = Int             // length of board strip, word, etc.
  type NumBlanks = Int          // number of blanks in a board strip
  type LetterCombo = String     // combination of letters (sorted with dups)
  type DictWord = String        // dictionary word
  type WordsByCombo = Map[LetterCombo, List[DictWord]] // words by letter combination

  val english = "en"
  val defaultLanguageCode = english

  val blankChar: Char = ' '
  def isBlankChar(ch: Char): Boolean = ch == blankChar
  val blackChar: Char = '-'
  def isBlackChar(ch: Char): Boolean = ch == blackChar

  def stringToLetterCombo(s: String): LetterCombo = s.sorted

  def computeCombosGroupedByLength(letters: String): Map[Length, List[LetterCombo]] = {
    computeCombos(letters).groupBy(_.length)
  }

  def computeCombos(letters: String): List[LetterCombo] = {
    // remove the empty combo (head) and convert elements to sort strings
    computeCombosUnsorted(letters.toList).tail.map(_.sorted.mkString)
  }

  /** includes the empty combo as the first element */
  private def computeCombosUnsorted(letters: List[Char]): List[List[Char]] = {
    letters match {
      case Nil => List(Nil)
      case head :: tail =>
        val tailCombos = computeCombosUnsorted(tail)
        val headCombos = tailCombos.map(head :: _)
        tailCombos ++ headCombos
    }
  }

  def mergeLetterCombos(combo1: LetterCombo, combo2: LetterCombo): LetterCombo =
    stringToLetterCombo(combo1.concat(combo2))

  /**
    * Compute the set of all versions of a string masked by replacing
    * 0 to n of its characters with blanks.
    *
    * @param s The string.
    * @param n Maximum number of characters to mask.
    * @return Masked versions of the string.
    */
  def maskWithBlanks(s: String, n: Int): List[String] = {
    def prepend(ch: Char, set: List[String]) = set map { ch +: _ }
    val maskedSet =
      if (n == 0)
        List(s)
      else if (s.length == 1)
        List(blankChar.toString, s) // n > 0 but we can have at most 1 blank in this case, i.e., 0 or 1.
      else
        prepend(s.head, maskWithBlanks(s.tail, n)) ++ prepend(blankChar, maskWithBlanks(s.tail, n - 1))
    maskedSet
  }
}
