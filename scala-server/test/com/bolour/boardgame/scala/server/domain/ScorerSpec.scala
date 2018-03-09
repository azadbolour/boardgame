package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.plane.scala.domain.Axis
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class ScorerSpec extends FlatSpec with Matchers {
  val logger = LoggerFactory.getLogger(this.getClass)

  val dimension = 15
  val middle = dimension / 2
  val trayCapacity = 7

  def playInfo(word: String, strip: Strip): List[PlayPiece] = {
    ((0 until word.length) map { i: Int =>
      val ch = word(i)
      val point = strip.point(i)
      val moved = WordUtil.isBlankChar(strip.content(i))
      PlayPiece(Piece(ch, ""), point, moved)
    }).toList
  }

  val pointValues = List.fill(dimension, dimension)(1)

   val scorer = Scorer(dimension, trayCapacity, pointValues)

  "basic scoring with point values of 1" should "score correctly based on worth of letters" in {
    val info = playInfo("JOIN", Strip(Axis.X, 0, 0, 3, " O  "))
    logger.info(s"play pieces: ${info}")
    scorer.scoreWord(info) shouldEqual 3
  }

  // TODO. Add scoring tests with larger point values.
}
