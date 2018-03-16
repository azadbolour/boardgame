/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.util.scala.common

import scala.io.{Source, BufferedSource}
import org.scalatest.{FlatSpec, Matchers}

class CompactStringSetSpec extends FlatSpec with Matchers {

  val runtime = Runtime.getRuntime

  def printMemory = {
    val memory = runtime.totalMemory()
    val freeMemory = runtime.freeMemory()
    val usedMemory = memory - freeMemory

    println(s"used memory: ${usedMemory}, free memory: ${freeMemory}")
  }

  "compact string set" should "store and retrieve strings" in {
    val set = new CompactStringSet()
    set.insert("one")
    set.insert("two")
    set.contains("one") shouldBe true
    set.contains("two") shouldBe true
    set.contains("three") shouldBe false

    set ++ List("four", "five").toIterator
    set.contains("four") shouldBe true
    set.contains("five") shouldBe true
    set.contains("one") shouldBe true

  }

  // Memory and timing test. Time-consuming.
//  "compact string set" should "have little memory overhead" in {
//    val begin = System.currentTimeMillis()
//    val source = Source.fromFile("dict/en-masked-words.txt")
//    val maskedWords = source.getLines
//    printMemory
//    val set = new CompactStringSet()
//    set ++ maskedWords
//    val end = System.currentTimeMillis()
//    val time = (end - begin)/1000
//    println(s"time: ${time} seconds")
//    printMemory
//    println(s"number of buckets: ${set.buckets.size}")
//
//  }

}
