/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @model Play */

// TODO. Maybe overkill to make a class for this. Just use playPiece in its place.

/**
 * Information about an in-progress play consisting of
 * a series of moves of pieces from the tray to the board
 * in constructing a new word on the board.
 */
class Play {
  constructor(playPieces) {
    /**
     * Contiguous line segment, horizontal or vertical
     * representing the word being constructed.
     *
     * @type {Array}
     */
    this.playPieces = playPieces;
  }

  moves() {
    let movedPlayPieces = this.playPieces.filter(p => p.moved);
    let movedGridPieces = movedPlayPieces.map(p => p.gridPiece);
    return movedGridPieces;
  }

  /**
   * Is an (row, col) board position adjacent to either end of a line segment?
   *
   * @param lineSegment The line segment on the board. The line segment
   *    is an array whose members have row and col fields.
   * @param pos The (row, col) position to be tested.
   * @param direction > 0 extends to the right, otherwise extends to the left.
   *
   * TODO. Obsolete. Remove.
   */
  static extendsLineSegment(lineSegment, pos, direction) {
    let len = lineSegment.length;
    if (len == 0) return true;

    let horizontal = (pos.row === lineSegment[0].row);
    let vertical = (pos.col = lineSegment[0].col);

    if (!vertical && !horizontal) return false; // Not in line.
    if (vertical && horizontal) return false; // Same position - does not extend.

    let endIndex = (direction <= 0) ? 0 : len - 1;
    let increment = (direction <= 0) ? (+1) : (-1);
    let lineEnd = lineSegment[endIndex];

    return vertical && pos.col === lineEnd.col + increment
      || horizontal && pos.row === lineEnd.row + increment;
  }

}


export default Play;