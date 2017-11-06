/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */



import {stringify} from "../util/Logger";

import {NO_PIECE} from "../domain/Piece";
import {checkArray, checkArrayIndex, checkCapacityOverflow} from "../util/MiscUtil";

export const mkEmptyTray = function(capacity) {
  let pieces = new Array(capacity);
  pieces.fill(NO_PIECE);
  return mkTray(capacity, pieces);
};

export const mkTray = function(capacity, pieces) {

  checkArray(pieces, "cannot construct tray from non-array pieces");
  checkCapacityOverflow(pieces.length, capacity, "cannot construct tray");

  let _capacity = capacity;
  let _pieces = pieces.slice();

  return {
    get capacity() { return _capacity; },
    get pieces() { return pieces.slice(); },

    size: function() { return pieces.length},

    piece: function(index) {
      checkArrayIndex(index, this.size, "tray index out bounds");
      return pieces[index];
    },

    isTrayPiece: function(piece) {
      let index = this.findIndexByPieceId(piece.id);
      let exists = index >= 0;
      return exists;
    },

    findIndexByPieceId: function(id) {
      const index = _pieces.findIndex(function(piece) {
        return (piece.id === id);
      });
      return index;
    },

    findExpectedIndexByPieceId: function(id, message) {
      let index = this.findIndexByPieceId(id);
      if (index === -1)
        throw {
          name: "not found",
          message: `${message} - expected piece not found - id: ${id}`
        };
      return index;
    },

    addPiece: function(piece) {
      checkCapacityOverflow(_pieces.length + 1, _capacity, "unable to add piece - tray is at capacity");
      let elements = _pieces.concat([piece]);
      return mkTray(_capacity, elements);
    },

    addPieces: function(addedPieces) {
      checkArray(addedPieces, "cannot add non-array to tray");
      let concatenated = _pieces.concat(addedPieces);
      checkCapacityOverflow(concatenated.length, _capacity, "unable to add pieces - tray capacity would be exceeded");
      return mkTray(_capacity, concatenated);
    },

    removePiece: function(id) {
      let index = this.findExpectedIndexByPieceId(id, "cannot remove piece");
      let elements = _pieces.slice(); // Shallow copy of immutable pieces. OK.
      elements.splice(index, 1);
      return mkTray(_capacity, elements);
    },

    replacePiece: function(id, replacementPiece) {
      let index = this.findExpectedIndexByPieceId(id, "cannot replace piece");
      let elements = _pieces.slice();
      elements.splice(index, 1, replacementPiece);
      return mkTray(_capacity, elements);
    },

    mapPieces(f) {
      return _pieces.map(f);
    }
  };
};
  