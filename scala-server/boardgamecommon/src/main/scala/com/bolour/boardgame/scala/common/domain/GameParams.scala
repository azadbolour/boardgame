/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

import com.bolour.boardgame.scala.common.domain.PieceProviderType.PieceProviderType

/**
  * Properties of a game to be started.
  *
  * @param dimension The dimension of the board.
  * @param trayCapacity The number of pieces (tiles) in each player's tray.
  * @param languageCode The id of the game's language. Determines the word dictionary to use.
  *                     This is the standard underscore-separated locale identifier.
  * @param playerName TODO. Should be separated out.
  * @param pieceProviderType The type of factory to use for generating new pieces (tiles).
  */
case class GameParams(
  dimension: Int,
  trayCapacity: Int,
  languageCode: String,
  playerName: String,
  pieceProviderType: PieceProviderType
)
