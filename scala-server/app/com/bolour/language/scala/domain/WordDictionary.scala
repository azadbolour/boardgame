/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.language.scala.domain

import java.io.{BufferedReader, File, FileReader}

import com.bolour.boardgame.scala.server.util.WordUtil._
import com.bolour.language.scala.domain.WordDictionary._
import com.bolour.util.scala.common.CompactStringSet
import com.bolour.util.scala.server.BasicServerUtil.{mkFileSource, mkResourceSource}

import scala.util.Try

/**
  * Word dictionary - indexed by combinations of letters in a word.
  * A combination is represented as the sorted string of letters.
  *
  * The dictionary also includes an index of "dense" masked words. A masked word
  * is a word some of whose letters have been changed to blanks (for the purpose
  * of matching with the contents of strips on the board). If a strip
  * is at all playable, then its content as a masked word must exist in the
  * masked words index. However, we do not store all masked versions of
  * a word: only those that are "dense", that is, those that only have a few
  * blanks. This index is used in identifying blanks that cannot possibly
  * be filled, because their eligible play strips are all dense but have contents
  * that do not exist as masked words in the masked word index.
  *
  * The class MaskedWordsPreprocessor is used to pre-compute dense masked words.
  *
  * Dictionary files reside in the "dict" directory. The words file is named
  * "${languageCode}${dictionaryFileSuffix}", where languageCode is the locale
  * code for the language, e.g., "en", and dictionaryFileSuffix = "-words.txt".
  * Similarly, the masked words file is named "${languageCode}${maskedWordsFileSuffix}",
  * where maskedWordsFileSuffix = "-masked-words.txt".
  */
// case class WordDictionary(languageCode: String, words: List[DictWord], maskedWords: Set[String], maxMaskedLetters: Int) {
case class WordDictionary(languageCode: String, words: List[DictWord], maskedWords: CompactStringSet, maxMaskedLetters: Int) {

  /**
    * Map of letter combinations to words in the dictionary.
    */
  private val wordsByCombo = mkWordsByCombo(words)

  /**
    * Is the given word in the dictionary?
    */
  def hasWord(word: String): Boolean = permutations(stringToLetterCombo(word)) contains word

  def hasMaskedWord(maskedWord: String): Boolean = maskedWords.contains(maskedWord)

  /**
    * Get the words in the dictionary that have exactly the same letters
    * as the given sorted list of letter.
    * */
  def permutations(combo: LetterCombo): List[DictWord] = wordsByCombo.getOrElse(combo, Nil)
}

object WordDictionary {

  def mkWordDictionary(languageCode: String, dictionaryDir: String, maxMaskedLetters: Int): Try[WordDictionary] = {
    for {
      words <- readDictionary(languageCode, dictionaryDir)
      maskedWords <- readMaskedWordsCompact(languageCode, dictionaryDir)
    } yield WordDictionary(languageCode, words, maskedWords, maxMaskedLetters)
  }

  private val classLoader = this.getClass.getClassLoader

  val dictionaryFileSuffix = "-words.txt"
  val maskedWordsFileSuffix = "-masked-words.txt"

  private def dictionaryFileName(languageCode: String): String =
    s"${languageCode}${dictionaryFileSuffix}"

  private def maskedWordsFileName(languageCode: String): String =
    s"${languageCode}${maskedWordsFileSuffix}"

  def readDictionary(languageCode: String, dictionaryDir: String): Try[List[DictWord]] = {
    val name = dictionaryFileName(languageCode)
    val path = s"${dictionaryDir}${File.separator}${name}"
    for {
      source <- mkFileSource(path).orElse(mkResourceSource(path, WordDictionary.classLoader))
      words <- Try {
        // TODO. Better pattern for closing source?
        try {
          val lines = source.getLines().toList
          lines.map(_.toUpperCase)
        }
        finally {source.close}
      }
    } yield words
  }

  def readMaskedWords(languageCode: String, dictionaryDir: String): Try[Set[String]] = {
    val name = maskedWordsFileName(languageCode)
    val path = s"${dictionaryDir}${File.separator}${name}"
    for {
      source <- mkFileSource(path).orElse(mkResourceSource(path, WordDictionary.classLoader))
      maskedWords <- Try {
        try {
          val lines = source.getLines().toSet
          lines.map(_.toUpperCase)
        }
        finally {source.close}
      }
    } yield maskedWords
  }

  def readMaskedWordsCompact(languageCode: String, dictionaryDir: String): Try[CompactStringSet] = {
    val name = maskedWordsFileName(languageCode)
    val path = s"${dictionaryDir}${File.separator}${name}"
    for {
      source <- mkFileSource(path).orElse(mkResourceSource(path, WordDictionary.classLoader))
      set <- Try {
        try {
          val lines = source.getLines()
          val uppers = lines.map(_.toUpperCase)
          CompactStringSet(uppers)
        }
        finally {source.close}
      }
    } yield set
  }

  // Using BufferedReader is 20% slower than using source, but uses slightly less memory.
  def readMaskedWordsCompactAsStream(languageCode: String, dictionaryDir: String): Try[CompactStringSet] = {
    val name = maskedWordsFileName(languageCode)
    val path = s"${dictionaryDir}${File.separator}${name}"
    for {
      // source <- mkFileSource(path).orElse(mkResourceSource(path, WordDictionary.classLoader))
      reader: BufferedReader <- Try {new BufferedReader(new FileReader(path))}
      set <- Try {
        try {
          val lines = reader.lines()
          val uppers: java.util.stream.Stream[String] = lines.map(_.toUpperCase)
          CompactStringSet(uppers)
        }
        finally {reader.close}
      }
    } yield set
  }

  /**
    * Create a map of letter combinations to words in the dictionary.
    * The combinations of letters in a word is represented by the sorted
    * list of the letters in teh word.
    */
  def mkWordsByCombo(words: List[DictWord]): WordsByCombo = words.groupBy(stringToLetterCombo)

  /**
    * Given the words in the dictionary, created the set of all dense masked versions
    * of the words. A dense masked version of the word has up to "maxMaskedLetters"
    * of its letters "masked" (that is replaced) by blanks.
    */
  def mkMaskedWords(words: List[DictWord], maxMaskedLetters: Int): Set[String] = {
    val list = for {
      word <- words
      masked <- maskWithBlanks(word, maxMaskedLetters)
    } yield masked
    list.toSet
  }

  def mkMaskedWordsCompact(words: List[DictWord], maxMaskedLetters: Int): CompactStringSet = {
    val list = for {
      word <- words
      masked <- maskWithBlanks(word, maxMaskedLetters)
    } yield masked
    CompactStringSet(list)
  }
}

