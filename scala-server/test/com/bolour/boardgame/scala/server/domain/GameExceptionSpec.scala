/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.server.domain.GameExceptions.InvalidCrosswordsException
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class GameExceptionSpec extends FlatSpec with Matchers {
  val logger = LoggerFactory.getLogger(this.getClass)

  "invalid crosswords" should "produce reasonable message" in {
    val invalidWords = List("prindle", "gradler")
    val exception = InvalidCrosswordsException("en", invalidWords)
    val message = exception.getMessage
    logger.info(message)
  }

}
