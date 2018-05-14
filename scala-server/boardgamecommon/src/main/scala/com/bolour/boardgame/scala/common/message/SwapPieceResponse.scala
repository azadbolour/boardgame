/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.{GameMiniState, Piece}

/**
  * API response to a request to swap a piece.
  *
  * @param gameMiniState Mini-state of the game after the swap.
  * @param piece The replacement piece.
  */
case class SwapPieceResponse(
  gameMiniState: GameMiniState,
  piece: Piece
)
