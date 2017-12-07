/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

import com.bolour.util.BasicUtil._

case class Piece(value: Char, id: String = stringId()) {
  import Piece._

  def isEmpty = this == noPiece
}

// TODO. Why doesn't just Piece work?
object Piece {
  type Pieces = List[Piece]
  val noPieceValue = '\u0000'
  val blank = ' '
  val noPieceId = "-1"
  val noPiece = Piece(noPieceValue, noPieceId)
  def isBlank(ch: Char) = ch == blank

  def notPieceValue(ch: Char): Boolean = ch != noPieceValue

  /** get list of characters for pieces and convert null characters to blanks */
  def piecesToString(pieces: List[Piece]): String =
    pieces.map(pc => if (pc.isEmpty) ' ' else pc.value).mkString

  val frequencies = List(
    ('A', 9),
    ('B', 2),
    ('C', 2),
    ('D', 4),
    ('E', 10),
    ('F', 2),
    ('G', 3),
    ('H', 2),
    ('I', 9),
    ('J', 1),
    ('K', 1),
    ('L', 4),
    ('M', 2),
    ('N', 6),
    ('O', 8),
    ('P', 2),
    ('Q', 1),
    ('R', 6),
    ('S', 4),
    ('T', 6),
    ('U', 4),
    ('V', 2),
    ('W', 2),
    ('X', 1),
    ('Y', 2),
    ('Z', 1)
  )

  // TODO. blank: 0.
  val worths = Map(
    'A' -> 1,
    'B' -> 3,
    'C' -> 3,
    'D' -> 2,
    'E' -> 1,
    'F' -> 4,
    'G' -> 2,
    'H' -> 4,
    'I' -> 1,
    'J' -> 8,
    'K' -> 5,
    'L' -> 1,
    'M' -> 3,
    'N' -> 1,
    'O' -> 1,
    'P' -> 3,
    'Q' -> 10,
    'R' -> 1,
    'S' -> 1,
    'T' -> 1,
    'U' -> 1,
    'V' -> 4,
    'W' -> 4,
    'X' -> 8,
    'Y' -> 4,
    'Z' -> 10
  )

  // TODO. Add blanks. Frequency 2.

  val frequencyMap = Map(frequencies:_*)

  /** cumulative distribution function of letters */
  val distribution = frequencies.tail.scanLeft(frequencies.head) (
    (cumulative, element) => (cumulative, element) match {
      case ((letter, cumWeight), (nextLetter, weight)) =>
        (nextLetter, cumWeight + weight)
    }
  )

  val maxDistribution: Int = distribution.last._2

  def randomLetter(): Char = {
    val distLevel: Int = (Math.random() * maxDistribution).toInt
    distribution.find(_._2 >= distLevel).get._1
  }

  def randomPiece(id: String) = Piece(randomLetter(), id)

  def leastFrequentLetter(letters: String): Option[Char] = {
    def freq(c: Char) = frequencyMap(c)
    def least(chars: List[Char]): Char =
      chars.reduce( (c1, c2) => if (freq(c1) <= freq(c2)) c1 else c2 )
    letters.toList match {
      case Nil => None
      case _ => Some(least(letters.toList))
    }
  }

}
