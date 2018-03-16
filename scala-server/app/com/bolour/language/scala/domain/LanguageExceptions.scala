/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.language.scala.domain

object LanguageExceptions {
  sealed abstract class LanguageException(cause: Throwable = null) extends Exception(cause) {
    def causeMessage = if (cause == null) "" else s" - caused by: ${cause.getMessage}"
  }

  case class MissingDictionaryException(languageCode: String, dictionaryDir: String, cause: Throwable) extends LanguageException(cause) {
    override def getMessage: String = s"unable to read dictionary for language code: ${languageCode} from dictionary directory ${dictionaryDir}${causeMessage}"
  }

}
