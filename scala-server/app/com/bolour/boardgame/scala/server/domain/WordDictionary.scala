/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import java.io.File

import com.bolour.util.BasicUtil.{mkFileSource, mkResourceSource}
import com.bolour.boardgame.scala.server.util.WordUtil._

import scala.io.{BufferedSource, Source}
import scala.util.{Failure, Success, Try}

/** Word dictionary - indexed by combinations of letters in a word.
  * A combination is represented as the sorted string of letters.
  *
  * @param languageCode The ISO language code of the dictionary.
  * @param index Index of words by their sorted letters.
  */
case class WordDictionary(languageCode: String, index: WordIndex) {

  /** Is the given word in the dictionary? */
  def hasWord(word: String): Boolean = permutedWords(stringToLetterCombo(word)) contains word

  /** Get the words in the dictionary that have exactly the same letters
    * as the given sorted list of letter. */
  def permutedWords(combo: LetterCombo): List[DictWord] = index.getOrElse(combo, Nil)
}

object WordDictionary {

  def apply(languageCode: String, words: List[DictWord]): WordDictionary =
    WordDictionary(languageCode, mkWordIndex(words))

  def apply(languageCode: String, dictionaryDir: String): WordDictionary = {
    readDictionary(languageCode, dictionaryDir) match {
      case Failure(ex) => throw ex
      case Success(dict) => dict
    }
  }

  val classLoader = this.getClass.getClassLoader

  val dictionaryFileSuffix = "-words.txt"

  private def dictionaryFileName(languageCode: String): String =
    s"${languageCode}${dictionaryFileSuffix}"

  def readDictionary(languageCode: String, dictionaryDir: String): Try[WordDictionary] = {
    val name = dictionaryFileName(languageCode)
    val path = s"${dictionaryDir}${File.separator}${name}"
    for {
      source <- mkFileSource(path).orElse(mkResourceSource(path))
      words <- Try {
        // TODO. Better pattern for closing source?
        try {
          val lines = source.getLines().toList
          lines.map(_.toUpperCase)
        }
        finally {source.close}
      }
    } yield WordDictionary(languageCode, words)
  }

  private def mkWordIndex(words: List[DictWord]): WordIndex = words.groupBy(stringToLetterCombo)
}

