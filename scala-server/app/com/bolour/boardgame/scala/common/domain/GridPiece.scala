/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

// TODO. Change to the more general: GridValue[Val](value: Val, point: Point]
// Will need custom json format.
case class GridPiece(value: Piece, point: Point)
