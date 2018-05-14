/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

import com.bolour.plane.scala.domain.Point

/**
  * Combination of a piece and its location on the board.
  */
case class PiecePoint(piece: Piece, point: Point)
