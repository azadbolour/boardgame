/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.{GameMiniState, Piece}
import com.bolour.plane.scala.domain.Point

/**
  * API response to a request to commit a play by the user.
  *
  * @param gameMiniState Mini-state of the game after the play.
  * @param replacementPieces Pieces to replace the user's played pieces.
  * @param deadPoints Empty points on the board that have been determined to be
  *                   no longer playable after the user's play was laid out on the board.
  */
case class CommitPlayResponse(
  gameMiniState: GameMiniState,
  replacementPieces: List[Piece],
  deadPoints: List[Point]
)
