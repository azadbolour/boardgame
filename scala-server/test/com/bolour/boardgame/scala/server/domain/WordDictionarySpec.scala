/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.domain

import com.bolour.language.scala.domain.WordDictionary
import org.scalatest.{FlatSpec, Matchers}
import com.bolour.language.scala.domain.WordDictionary._
import org.slf4j.LoggerFactory

class WordDictionarySpec extends FlatSpec with Matchers {
  val logger = LoggerFactory.getLogger(this.getClass)

  val runtime = Runtime.getRuntime

  def printMemory = {
    val memory = runtime.totalMemory()
    val freeMemory = runtime.freeMemory()
    val usedMemory = memory - freeMemory

    println(s"used memory: ${usedMemory}, free memory: ${freeMemory}")
  }

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

  "masked words" should "be read" in {
    val dictionary = WordDictionary.mkWordDictionary("tiny", "dict", 3).get
    println(dictionary.maskedWords)
    dictionary.hasMaskedWord("N T") shouldBe true
  }

//  "reading large masked word set" should "be efficient" in {
//    printMemory
//    val begin = System.currentTimeMillis()
//    val set = WordDictionary.readMaskedWordsCompact("en", "dict").get
//    set.contains("WORD") shouldBe true
//    val end = System.currentTimeMillis()
//    val time = (end - begin)/1000
//    printMemory
//    println(s"time: ${time} seconds")
//
//  }
}
