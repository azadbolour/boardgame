/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import java.time.Instant

import com.bolour.boardgame.scala.common.domain.PieceProviderType.PieceProviderType
import com.bolour.util.scala.common.CommonUtil.{ID}
import com.bolour.util.scala.server.BasicServerUtil.{stringId}
import com.bolour.boardgame.scala.common.domain.{GameParams, Piece}
import com.bolour.boardgame.scala.server.util.WordUtil.english

case class Game(
  id: ID,
  dimension: Int,
  trayCapacity: Int,
  languageCode: String,
  pieceProviderType: PieceProviderType,
  pointValues: List[List[Int]],
  playerId: ID,
  startTime: Instant,
  endTime: Option[Instant]
) {
  // def mkPieces(num: Int): List[Piece] = List.fill(num){pieceGenerator.take()}

  val scorer = Scorer(dimension, trayCapacity, pointValues)
}

object Game {

  def apply(p: GameParams, pointValues: List[List[Int]], playerId: ID): Game = {
    val now = Instant.now()
    val lang = p.languageCode
    val languageCode = if (!lang.isEmpty) lang else english
    val genType = p.pieceProviderType
    Game(stringId, p.dimension, p.trayCapacity, languageCode, genType, pointValues, playerId, now, None)
  }

}

