package com.bolour.language.scala.service

import java.io.PrintWriter

import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.util.scala.server.WordListFilter.args
import org.slf4j.LoggerFactory

import scala.collection.mutable
import scala.io.Source

object MaskedWordsPreprocessor extends App {
  val logger = LoggerFactory.getLogger(this.getClass)

  if (args.length < 3) {
    logger.error("usage: MaskedWordPreprocessor wordsFile outFile maxBlanks")
    System.exit(-1)
  }

  val wordsFile = args(0)
  val outFile = args(1)
  val maxBlanks = args(2).toInt

  // val mobyFile = "dict/moby-english.txt"
  val mobySource = Source.fromFile(wordsFile)
  val words = mobySource.getLines()

  val runtime = Runtime.getRuntime

  printMemory(runtime)

  val out = new PrintWriter(outFile)

  words.foreach { word =>
    val maskedWords = WordUtil.maskWithBlanks(word, maxBlanks)
    maskedWords.foreach { out.println }
  }

  out.close()

  printMemory(runtime)

  runtime.gc()
  printMemory(runtime)

  val t1 = System.currentTimeMillis()
  val maskedInputSource = Source.fromFile(outFile)
  val maskedWords = maskedInputSource.getLines().toSet
  val t2 = System.currentTimeMillis()
  println(s"number of masked words: ${maskedWords.size}")
  val elapsed = (t2 - t1)/1000
  println(s"time to load masked words: ${elapsed}")
  
  val num = maskedWords.size
  println(s"number of masked words: ${num}")

  printMemory(runtime)
  runtime.gc()
  printMemory(runtime)

  val s = maskedWords.size
  println(s"masked words set size: ${s}")

  def printMemory(runtime: Runtime) = {
    val memory = runtime.totalMemory()
    val freeMemory = runtime.freeMemory()
    val usedMemory = memory - freeMemory

    println(s"used memory: ${usedMemory}, free memory: ${freeMemory}")
  }

}
