/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

/**
  * A piece (tile) used in the game.
  *
  * @param value An upper-case alphabetic character.
  * @param id The unique identifier of the piece within a game.
  */
case class Piece(value: Char, id: String)

object Piece {
  type Pieces = List[Piece]

  /**
    * Normalize the letter frequencies to obtain a given rough total
    * return the normalized frequencies and the actual total.
    */
  def normalizedFrequencies(roughTotal: Int): (Map[Char, Int], Int) = {
    val factor: Float = roughTotal.toFloat / maxDistribution.toFloat
    def normalizer(frequency: Int) = Math.round(frequency * factor).max(1)

    val normalized = frequencyMap mapValues normalizer
    val actualTotal = normalized.values.sum
    (normalized, actualTotal)
  }

  val frequencies = List(
    ('A', 81),
    ('B', 15),
    ('C', 28),
    ('D', 42),
    ('E', 127),
    ('F', 22),
    ('G', 20),
    ('H', 61),
    ('I', 70),
    ('J', 2),
    ('K', 8),
    ('L', 40),
    ('M', 24),
    ('N', 67),
    ('O', 80),
    ('P', 19),
    ('Q', 1),
    ('R', 60),
    ('S', 63),
    ('T', 91),
    ('U', 28),
    ('V', 10),
    ('W', 23),
    ('X', 2),
    ('Y', 20),
    ('Z', 1)
  )

  val frequencyMap = Map(frequencies:_*)

  /**
    * Cumulative distribution function of letters.
    */
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
