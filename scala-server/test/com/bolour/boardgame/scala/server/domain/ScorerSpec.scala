package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain.Axis.Axis
import com.bolour.boardgame.scala.common.domain._
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._
import com.bolour.boardgame.scala.common.domain.ScoreMultiplier._



class ScorerSpec extends FlatSpec with Matchers {
  val logger = LoggerFactory.getLogger(this.getClass)

  val dimension = 15
  val middle = dimension / 2
  val trayCapacity = 7

  def playInfo(word: String, strip: Strip): List[(Char, Point, Boolean)] = {
    ((0 until word.length) map { i: Int =>
      val ch = word(i)
      // val piece = Piece(ch, i.toString)
      val point = strip.point(i)
      val moved = Piece.isBlank(strip.content(i))
      (ch, point, moved)
    }).toList
  }

  def worth(letter: Char) = Piece.worths(letter)

  val x1 = noMultiplier()
  val x2Letter = letterMultiplier(2)
  val x3Letter = letterMultiplier(3)
  val x2Word = wordMultiplier(2)
  val x3Word = wordMultiplier(3)

   val scorer = Scorer(dimension, trayCapacity)
   val multiplierGrid = scorer.multiplierGrid

   def multiplier(row: Int, col: Int): ScoreMultiplier = multiplierGrid.cell(Point(row, col))

  "specific score multipliers" should "check" in {
    val m82_9 = ScoreMultiplier.scoreMultiplier(Point(8, 2), 9)
    println(m82_9)
    m82_9 shouldEqual x2Letter
  }

   "score multipliers" should "follow the rules" in {
    multiplier(middle, middle) shouldEqual x2Word
    multiplier(0, 0) shouldEqual x3Word
    multiplier(0, 1) shouldEqual x1
    multiplier(0, 2) shouldEqual x1
    multiplier(0, 3) shouldEqual x1
    multiplier(0, 4) shouldEqual x2Letter
    multiplier(0, 5) shouldEqual x1
    multiplier(0, 6) shouldEqual x1
    multiplier(0, 7) shouldEqual x3Word

    multiplier(1, 0) shouldEqual x1
    multiplier(1, 1) shouldEqual x2Word
    multiplier(1, 2) shouldEqual x1
    multiplier(1, 3) shouldEqual x1
    multiplier(1, 4) shouldEqual x1
    multiplier(1, 5) shouldEqual x3Letter
    multiplier(1, 6) shouldEqual x1
    multiplier(1, 7) shouldEqual x1

    multiplier(7, 7) shouldEqual x2Word
    multiplier(8, 7) shouldEqual x1
    multiplier(9, 7) shouldEqual x1
    multiplier(10, 7) shouldEqual x1
    multiplier(11, 7) shouldEqual x2Letter
    multiplier(12, 7) shouldEqual x1
    multiplier(13, 7) shouldEqual x1
    multiplier(14, 7) shouldEqual x3Word
  }

  "scoring with 3 times word score" should "score correctly based on worth of letters" in {
    val info = playInfo("JOIN", Strip(Axis.X, 0, 0, 3, " O  "))
    logger.info(s"play pieces: ${info}")
    scorer.scoreWord(info) shouldEqual
      (3 * ( (worth('J') + worth('O') + worth('I') + worth('N'))))
  }

  "scoring with 2 time letter score" should "score correctly based on worth of letters" in {
    val info = playInfo("JOIN", Strip(Axis.X, 0, 0, 3, "J   "))
    scorer.scoreWord(info) shouldEqual
      (worth('J') + worth('O') + worth('I') + worth('N'))
  }


}
