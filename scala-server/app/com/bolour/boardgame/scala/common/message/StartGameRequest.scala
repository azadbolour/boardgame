/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.{GameParams, InitPieces, Piece, PiecePoint}

/**
  * API request to start a game.
  *
  * @param gameParams Basic specification of the game.
  * @param pointValues Point values attached to each board point (for scoring) - varies
  *                    from game to game.
  */
case class StartGameRequest(
  gameParams: GameParams,
  initPieces: InitPieces,
  pointValues: List[List[Int]]
)
