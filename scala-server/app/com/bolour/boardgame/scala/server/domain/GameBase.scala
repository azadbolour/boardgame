/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import java.time.Instant

import com.bolour.boardgame.scala.common.domain.PieceProviderType.PieceProviderType
import com.bolour.util.scala.common.CommonUtil.ID
import com.bolour.util.scala.server.BasicServerUtil.stringId
import com.bolour.boardgame.scala.common.domain.{GameParams, InitPieces, Piece, PiecePoint}
import com.bolour.boardgame.scala.server.util.WordUtil.english

/**
  * Properties of a game that are conceptually immutable once set.
  *
  * @param pointValues Values attached to each board square for scoring.
  * @param initPieces Initial pieces on board and in trays.
  * @param playerId Unique id of player.
  * @param startTime Time game began.
  * @param endTime Time game ended.
  */
case class GameBase(
  gameId: ID,
  gameParams: GameParams,
  initPieces: InitPieces,
  pointValues: List[List[Int]],
  playerId: ID,
  startTime: Instant,
  endTime: Option[Instant]
) {
  def scorer = Scorer(gameParams.dimension, gameParams.trayCapacity, pointValues)

  def end: GameBase = {
    val now = Instant.now()
    this.copy(endTime = Some(now))
  }
}

object GameBase {
  def apply(
    gameParams: GameParams,
    initPieces: InitPieces,
    pointValues: List[List[Int]],
    playerId: ID,
  ): GameBase = {
    val now = Instant.now()
    val languageCode = gameParams.languageCode
    val realLanguageCode = if (!languageCode.isEmpty) languageCode else english
    val params = gameParams.copy(languageCode = realLanguageCode)
    GameBase(stringId(), params, initPieces, pointValues, playerId, now, None)
  }

}

