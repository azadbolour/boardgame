/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.domain

import org.scalatest.{FlatSpec, Matchers}
import com.bolour.boardgame.scala.server.domain.WordDictionary._
import org.slf4j.LoggerFactory

class WordDictionarySpec extends FlatSpec with Matchers {
  val logger = LoggerFactory.getLogger(this.getClass)

  "mask words" should "be computed" in {
    val words = List("FOX", "RAT", "BIRD")
    val maskedWords1 = mkMaskedWords(words, 1)
    maskedWords1 should contain ("F X")
    maskedWords1 should not contain ("R  ")

    val maskedWords2 = mkMaskedWords(words, 2)
    maskedWords2 should contain ("F X")
    maskedWords2 should contain ("R  ")

    println(maskedWords2)
  }
}
