/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.{GameParams, PiecePoint, Piece}

case class StartGameResponse(
  gameId: String,
  gameParams: GameParams,
  gridPieces: List[PiecePoint],
  trayPieces: List[Piece]
)
