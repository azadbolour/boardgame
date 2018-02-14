/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.util

import org.scalatest.{FlatSpec, Matchers}
import com.bolour.boardgame.scala.server.util.WordUtil._
import org.slf4j.LoggerFactory

class WordUtilSpec extends FlatSpec with Matchers {
  val logger = LoggerFactory.getLogger(this.getClass)
  val letters = "ABC"

  "all letter combinations" should "be present for ABC" in {
    val map = computeCombosGroupedByLength(letters)
    logger.info(s"grouped combos: ${map}")
    map.get(0) shouldBe empty
    map(1).length shouldEqual 3
    map(3).length shouldEqual 1
    map(2) should contain ("AB")
    map(2).contains("BA") shouldEqual false
  }

  "all masked versions" should "be computed for ABCD" in {
    maskWithBlanks("ABCD", 2) should contain (" B D")
    maskWithBlanks("ABCD", 2) should contain ("AB D")
    maskWithBlanks("ABCD", 2) should not contain ("   D")
    maskWithBlanks("ABCD", 2).size shouldEqual (1 + 4 + 6)

    maskWithBlanks("ABC", 3).size shouldEqual (2 * 2 * 2)
    maskWithBlanks("ABC", 5).size shouldEqual (2 * 2 * 2)
    maskWithBlanks("ABC", 0).size shouldEqual 1

    maskWithBlanks("A", 0).size shouldEqual 1
    maskWithBlanks("A", 1).size shouldEqual 2
  }

}
