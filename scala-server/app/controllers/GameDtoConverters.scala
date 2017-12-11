/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package controllers

import com.bolour.boardgame.scala.common.domain.{GameParams, PlayPiece}
import com.bolour.boardgame.scala.common.domain.PlayerType.{UserPlayer, playerIndex}
import com.bolour.boardgame.scala.common.message._
import com.bolour.boardgame.scala.server.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions._

object GameDtoConverters {

  def toGameDto(params: GameParams, state: GameState): GameDto = {
    val gridPieces = state.board.gridPieces
    val userTray = state.trays(playerIndex(UserPlayer))
    GameDto(state.game.id, params, gridPieces, userTray.pieces.toList)
  }

  def fromPlayerDto(dto: PlayerDto): Player = Player(dto.name)

  def toMissingPieceErrorDto(ex: MissingPieceException) =
    MissingPieceErrorDto("MissingPieceError", ex.pieceId)

  def toMissingGameErrorDto(ex: MissingGameException) =
    MissingPieceErrorDto("MissingGameError", ex.gameId)

  def toMissingPlayerErrorDto(ex: MissingPlayerException) =
    MissingPlayerErrorDto("MissingPlayerError", ex.playerName)

  def toSystemOverloadedErrorDto(ex: SystemOverloadedException) =
    SystemOverloadedErrorDto("SystemOverloadedError")

  def toInvalidWordErrorDto(ex: InvalidWordException) =
    InvalidWordErrorDto("InvalidWordError", ex.languageCode, ex.word)

  def toInvalidCrosswordsErrorDto(ex: InvalidCrosswordsException) =
    InvalidCrosswordsErrorDto("InvalidCrosswordsError", ex.languageCode, ex.crosswords)

  def toUnsupportedLanguageErrorDto(ex: UnsupportedLanguageException) =
    UnsupportedLanguageErrorDto("UnsupportedLanguageError", ex.languageCode)

  def toMissingDictionaryErrorDto(ex: MissingDictionaryException) =
    MissingDictionaryErrorDto("MissingDictionaryError", ex.languageCode, ex.dictionaryDir)

  def toInternalErrorDto(ex: InternalGameException) =
    InternalErrorDto("InternalError", ex.message)
}
