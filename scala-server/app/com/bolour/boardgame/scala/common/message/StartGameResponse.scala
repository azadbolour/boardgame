/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.{GameParams, PiecePoint, Piece}

/**
  * API response for starting a game.
  *
  * @param gameId Unique id of the game.
  * @param gameParams The game parameters. In case some are assigned at the server.
  * @param boardPiecePoints The initial state of the board. TODO. Unnecessary.
  * @param trayPieces The user's initial tray  pieces.
  */
case class StartGameResponse(
  gameId: String,
  gameParams: GameParams,
  boardPiecePoints: List[PiecePoint],
  trayPieces: List[Piece]
)
