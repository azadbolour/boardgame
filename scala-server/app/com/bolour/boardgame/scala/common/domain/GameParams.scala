/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

import com.bolour.boardgame.scala.common.domain.PieceProviderType.PieceProviderType

case class GameParams(
  dimension: Int,
  trayCapacity: Int,
  languageCode: String,
  playerName: String, // TODO. Does not belong here.
  pieceProviderType: PieceProviderType
)
