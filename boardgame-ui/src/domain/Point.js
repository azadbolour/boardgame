/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


export const mkPoint = function(row, col) {
  let _row = row;
  let _col = col;

  return {
    get row() { return _row; },
    get col() { return _col; },
    clone: function() {
      return mkPoint(_row, _col)
    }
  };
};

export const eq = function(point1, point2) {
  return point1.row === point2.row && point1.col === point2.col;
};