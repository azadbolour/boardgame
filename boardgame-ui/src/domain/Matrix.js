/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {zipWith, checkArray, checkArrayIndex} from "../util/MiscUtil";
// import {stringify} from "../util/Logger";
// import {mkPoint} from "./Point";

// We only need matrices with the same number of rows and cols.
export const mkMatrixFromCoordinates = function(dimension, coordinatesToCellValue) {
  let rows = [];

  for (let r = 0; r < dimension; r++) {
    let row = [];
    for (let c = 0; c < dimension; c++) {
      row.push(coordinatesToCellValue(r, c));
    }
    rows.push(row);
  }

  return mkMatrix(dimension, rows);
};

export const mkMatrix = function(dimension, rows) {
  checkArray(rows, "matrix rows not an array");
  const numRows = rows.length;
  if (numRows !== dimension)
    throw {
      name: "illegal argument",
      message: `rows not equal to dimension - rows: ${numRows}, dimension: ${dimension}`
    };
  for (let r = 0; r < dimension; r++) {
    let len = rows[r].length;
    if (len !== dimension)
      throw {
        name: "illegal argument",
        message: `row ${r} length not equal to dimension - length: ${len}, dimension: ${dimension}`
      };
  }

  let _dimension = dimension;
  let _rows = rows;

  return {
    get dimension() { return _dimension; },

    rows: function() { return _rows.slice(); },
    cols: function() {
      let initCols = [];
      for (let i = 0; i < _dimension; i++)
        initCols.push([]);
      return _rows.reduce(function(cols, row) {
        return zipWith(cols, row, function(col, value) {
          col.push(value);
          return col;
        })
      }, initCols);
    },

    validatePoint: function(point) {
      checkArrayIndex(point.row, dimension, "row coordinate out of range");
      checkArrayIndex(point.col, dimension, "col coordinate out of range");
    },

    setElement: function(point, value) {
      this.validatePoint(point);
      let row = _rows[point.row];
      let clonedRow = row.slice();
      clonedRow.splice(point.col, 1, value);
      return this.updateRow(point.row, clonedRow);
    },

    getElement: function(point) {
      this.validatePoint(point);
      return _rows[point.row][point.col];
    },

    updateRow: function(index, row) {
      let clonedRows = _rows.slice();
      clonedRows.splice(index, 1, row);
      return mkMatrix(_dimension, clonedRows);
    },

    find(p) {
      for (let r = 0; r < _dimension; r++)
        for (let c = 0; c < _dimension; c++) {
          let element = _rows[r][c];
          if (p(element))
            return element;
        }
      return undefined;
    },
    
    reduce: function(f, init) {
      let linear = this.linearize();
      return linear.reduce(f, init);
    },

    every: function(p) {
      let linear = this.linearize();
      return linear.every(p);
    },

    some: function(p) {
      let linear = this.linearize();
      return linear.some(p);
    },

    linearize: function() {
      return _rows.reduce(function(linear, row) {
        return linear.concat(row);
      } ,[]);
    }
  }
};