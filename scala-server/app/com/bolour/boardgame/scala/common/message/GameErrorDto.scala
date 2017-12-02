/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

sealed abstract class GameErrorDto

case class MissingPieceErrorDto(tag: String, pieceId: String) extends GameErrorDto

case class MissingGameErrorDto(tag: String, gameId: String) extends GameErrorDto

case class MissingPlayerErrorDto(tag: String, playerName: String) extends GameErrorDto

case class SystemOverloadedErrorDto(tag: String) extends GameErrorDto

case class InvalidWordErrorDto(tag: String, languageCode: String, word: String) extends GameErrorDto

case class UnsupportedLanguageErrorDto(tag: String, languageCode: String)

case class MissingDictionaryErrorDto(tag: String, languageCode: String, dictionaryDir: String) extends GameErrorDto

case class InternalErrorDto(tag: String, message: String)