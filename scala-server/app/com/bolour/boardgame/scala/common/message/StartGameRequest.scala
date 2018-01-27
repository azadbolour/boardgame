/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.{GameParams, GridPiece, Piece}

case class StartGameRequest(
  gameParams: GameParams,
  initGridPieces: List[GridPiece],
  initUserPieces: List[Piece],
  initMachinePieces: List[Piece],
  pointValues: List[List[Int]]
)
