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

}
