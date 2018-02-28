/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import java.io.File

import com.bolour.boardgame.scala.server.domain.GameExceptions.MissingDictionaryException
import com.bolour.util.scala.server.util.BasicServerUtil.{mkFileSource, mkResourceSource}
import com.bolour.boardgame.scala.server.util.WordUtil._

import scala.collection.immutable.HashSet
import scala.collection.parallel.mutable.{ParHashSet, ParSet}
import scala.io.{BufferedSource, Source}
import scala.util.{Failure, Success, Try}
import WordDictionary._

import scala.collection.mutable

/** Word dictionary - indexed by combinations of letters in a word.
  * A combination is represented as the sorted string of letters.
  *
  * The dictionary also includes an index of "dense" masked words. A masked word
  * is a word some of whose letters have been changed to blanks (for the purpose
  * of matching with with the contents of strips on teh board). If a strip
  * is at all playable, then its content as a masked word must exist in the
  * masked words index. However, we do not store all masked versions of
  * a word: only those that are "dense", that is, those that only have a few
  * blanks. This index is used in identifying blanks that cannot possibly
  * be filled, because their eligible play strips are all dense but have contents
  * that do not exist as masked words in the masked word index.
  *
  * @param languageCode The ISO language code of the dictionary.
  * @param words List of words in the dictionary.
  */
case class WordDictionary(languageCode: String, words: List[DictWord], maxMaskedLetters: Int) {

  val wordsByCombo = mkWordsByCombo(words)
  val maskedWords = mkMaskedWords(words, maxMaskedLetters)

  /** Is the given word in the dictionary? */
  def hasWord(word: String): Boolean = permutations(stringToLetterCombo(word)) contains word

  def hasMaskedWord(maskedWord: String): Boolean = maskedWords.contains(maskedWord)

  /** Get the words in the dictionary that have exactly the same letters
    * as the given sorted list of letter. */
  def permutations(combo: LetterCombo): List[DictWord] = wordsByCombo.getOrElse(combo, Nil)
}

object WordDictionary {

//  def apply(languageCode: String, words: List[DictWord]): WordDictionary =
//    WordDictionary(languageCode, mkWordIndex(words))

  def mkWordDictionary(languageCode: String, dictionaryDir: String, maxMaskedLetters: Int): Try[WordDictionary] = Try {
    readDictionary(languageCode, dictionaryDir) match {
      case Failure(ex) => throw new MissingDictionaryException(languageCode, dictionaryDir, ex)
      case Success(words) => WordDictionary(languageCode, words, maxMaskedLetters)
    }
  }

  val classLoader = this.getClass.getClassLoader

  val dictionaryFileSuffix = "-words.txt"

  private def dictionaryFileName(languageCode: String): String =
    s"${languageCode}${dictionaryFileSuffix}"

  def readDictionary(languageCode: String, dictionaryDir: String): Try[List[DictWord]] = {
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
    } // yield WordDictionary(languageCode, words)
      yield words
  }

  // val MaxMaskedLetters = 2

  def mkWordsByCombo(words: List[DictWord]): WordsByCombo = words.groupBy(stringToLetterCombo)

  def mkMaskedWords(words: List[DictWord], maxMaskedLetters: Int): Set[String] = {
    val list = for {
      word <- words
      masked <- maskWithBlanks(word, maxMaskedLetters)
    } yield masked
    list.toSet
  }

//  def mkMaskedWords(words: List[DictWord], maxMaskedLetters: Int): mutable.HashSet[String] = {
//    // val wordSet = HashSet(words:_*)
//    val wordSet = listToSet(words)
//    for {
//      word <- wordSet
//      masked <- maskWithBlanks(word, maxMaskedLetters)
//    } yield masked
//  }

  private def listToSet[A](list: List[A]): mutable.HashSet[A] = {
    var set = mutable.HashSet[A]()
    list.foreach { element =>
      set += element
    }
    set
  }

}

