/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.{GameParams, PiecePoint, Piece}

/**
  * API request to start a game.
  *
  * @param gameParams Basic specification of the game.
  * @param initGridPieces Initial state of the board (pieces and their locations) - for testing.
  * @param initUserPieces Initial pieces in the user's tray - for testing.
  * @param initMachinePieces Initial pieces in machine's tray - for testing.
  * @param pointValues Point values attached to each board point (for scoring) - varies
  *                    from game to game.
  */
case class StartGameRequest(
  gameParams: GameParams,
  initGridPieces: List[PiecePoint],
  initUserPieces: List[Piece],
  initMachinePieces: List[Piece],
  pointValues: List[List[Int]]
)
