/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import * as Piece from './Piece';

/*
 * Grid piece has a double purpose: to represent a piece
 * at a particular board location, and to to represent
 * the movement of a piece to a particular board location.
 */
export const mkGridPiece = function(piece, point) {
  let _piece = piece;
  let _point = point;

  return {
    get piece() { return _piece; },
    get point() { return _point; }
  };
};

export const mkBareGridPiece = function(point) {
  return mkGridPiece(Piece.NO_PIECE, point);
};