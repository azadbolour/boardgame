/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package controllers

import com.bolour.util.scala.server.BasicServerUtil.stringId
import com.bolour.boardgame.scala.common.domain.PlayerType._
import com.bolour.boardgame.scala.common.message._
import com.bolour.boardgame.scala.server.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions._
import com.bolour.boardgame.scala.common.domain.GameParams

object GameDtoConverters {

  def mkStartGameResponse(params: GameParams, state: Game): StartGameResponse = {
    val piecePoints = state.board.piecePoints
    val userTray = state.trays(playerIndex(UserPlayer))
    StartGameResponse(state.gameBase.gameId, params, piecePoints, userTray.pieces.toList)
  }

  def fromPlayerDto(dto: PlayerDto): Player = Player(stringId, dto.name)

  def toMissingPieceErrorDto(ex: MissingPieceException) =
    MissingPieceErrorDto("MissingPieceError", ex.getMessage, ex.pieceId)

  def toMissingGameErrorDto(ex: MissingGameException) =
    MissingGameErrorDto("MissingGameError", ex.getMessage, ex.gameId)

  def toMissingPlayerErrorDto(ex: MissingPlayerException) =
    MissingPlayerErrorDto("MissingPlayerError", ex.getMessage, ex.playerName)

  def toSystemOverloadedErrorDto(ex: SystemOverloadedException) =
    SystemOverloadedErrorDto("SystemOverloadedError", ex.getMessage)

  def toInvalidWordErrorDto(ex: InvalidWordException) =
    InvalidWordErrorDto("InvalidWordError", ex.getMessage, ex.languageCode, ex.word)

  def toInvalidCrosswordsErrorDto(ex: InvalidCrosswordsException) =
    InvalidCrosswordsErrorDto("InvalidCrosswordsError", ex.getMessage, ex.languageCode, ex.crosswords)

  def toUnsupportedLanguageErrorDto(ex: UnsupportedLanguageException) =
    UnsupportedLanguageErrorDto("UnsupportedLanguageError", ex.getMessage, ex.languageCode)

  def toMissingDictionaryErrorDto(ex: MissingDictionaryException) =
    MissingDictionaryErrorDto("MissingDictionaryError", ex.getMessage, ex.languageCode, ex.dictionaryDir)

  def toMalformedPlayErrorDto(ex: MalformedPlayException) =
    MalformedPlayErrorDto("MalformedPlayError", ex.getMessage, ex.condition)

  def toInternalErrorDto(ex: InternalGameException) =
    InternalErrorDto("InternalError", ex.getMessage)
}
