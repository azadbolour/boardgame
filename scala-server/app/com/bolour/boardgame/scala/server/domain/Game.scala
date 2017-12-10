/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import java.time.Instant
import java.util.UUID

import com.bolour.util.BasicUtil.{ID, stringId}
import com.bolour.boardgame.scala.common.domain.{GameParams, Piece}
import com.bolour.boardgame.scala.server.util.WordUtil.english

case class Game(
  id: ID,
  dimension: Int,
  trayCapacity: Int,
  languageCode: String,
  playerId: ID,
  startTime: Instant,
  endTime: Option[Instant],
  pieceGenerator: PieceGenerator
) {
  def mkPieces(num: Int): List[Piece] = List.fill(num){pieceGenerator.next()}

  val scorer = Scorer(dimension, trayCapacity)
}

object Game {

  def apply(p: GameParams, playerId: ID, pieceGenerator: PieceGenerator = PieceGenerator.CyclicPieceGenerator()): Game = {
    val now = Instant.now()
    val lang = p.languageCode
    val languageCode = if (!lang.isEmpty) lang else english
    Game(stringId, p.dimension, p.trayCapacity, languageCode, playerId, now, None, pieceGenerator)
  }

}

