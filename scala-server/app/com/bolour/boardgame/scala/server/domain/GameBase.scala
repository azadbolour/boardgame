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
import com.bolour.boardgame.scala.common.domain.{GameParams, Piece, PiecePoint}
import com.bolour.boardgame.scala.server.util.WordUtil.english

/**
  * Properties of a game that are conceptually immutable once set.
  *
  * @param id Unique identifier.
  * @param dimension Of te board.
  * @param trayCapacity Number of pieces in a tray.
  * @param languageCode Locale of game's language (determines dictionary to use).
  * @param pieceProviderType Type of generator of new pieces for play.
  * @param pointValues Values attached to each board square for scoring.
  * @param playerId Unique id of player.
  * @param startTime Time game began.
  * @param endTime Time game ended.
  * @param piecePoints Initial pieces on the grid (used for testing).
  * @param initUserPieces Initial pieces to use for user player.
  * @param initMachinePieces Initial pieces to use for machine player.
  */
case class GameBase(
  id: ID,
  dimension: Int,
  trayCapacity: Int,
  languageCode: String,
  pieceProviderType: PieceProviderType,
  pointValues: List[List[Int]],
  playerId: ID,
  startTime: Instant,
  endTime: Option[Instant],
  piecePoints: List[PiecePoint],
  initUserPieces: List[Piece],
  initMachinePieces: List[Piece]
) {
  def scorer = Scorer(dimension, trayCapacity, pointValues)

  def end: GameBase = {
    val now = Instant.now()
    this.copy(endTime = Some(now))
  }
}

object GameBase {

  def apply(
    params: GameParams,
    pointValues: List[List[Int]],
    playerId: ID,
    piecePoints: List[PiecePoint] = Nil,
    initUserPieces: List[Piece] = Nil,
    initMachinePieces: List[Piece] = Nil,
  ): GameBase = {
    val now = Instant.now()
    val lang = params.languageCode
    val languageCode = if (!lang.isEmpty) lang else english
    val genType = params.pieceProviderType
    GameBase(stringId(), params.dimension, params.trayCapacity, languageCode, genType,
      pointValues, playerId, now, None, piecePoints, initUserPieces, initMachinePieces)
  }

}

