/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.util.scala.server

import org.slf4j.LoggerFactory

import scala.io.Source

object WordListFilter extends App {

  val logger = LoggerFactory.getLogger(this.getClass)

  if (args.length < 1) {
    logger.error("missing argument word frequency list file")
    System.exit(-1)
  }

  var mobyFile = "dict/moby-english.txt"
  val mobySource = Source.fromFile(mobyFile)
  val mobyWords = mobySource.getLines().toSet

  val frequencyFileName = args(0)

  val frequencySource = Source.fromFile(frequencyFileName)
  val lines = frequencySource.getLines().toList
  val frequencies = lines.map(_.split("\\s+")).map(arr => (arr(0), arr(1).toLong))
  val frequencyMap = Map(frequencies:_*)
  val frequencyWords = frequencyMap.keySet

  val intersection = frequencyWords.intersect(mobyWords)
  val difference = frequencyWords diff intersection
  val filtered = frequencyMap.filterKeys { word => intersection.contains(word)}

  val tuples = filtered.toList
  implicit val frequencyOrdering = Ordering.by[(String, Long), Long](_._2).reverse
  // val ordered = TreeSet(tuples:_*)
  val sortedTuples = tuples.sorted

  logger.info(s"number of words in the intersection of moby and frequencies: ${filtered.size}")
  logger.info(s"number of tuples: ${tuples.size}")
  logger.info(s"number of ordered: ${sortedTuples.size}")
  sortedTuples.foreach { case (word, freq) => println(s"${word} ${freq}") }
  difference.foreach { word => println(word) }

}
