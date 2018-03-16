/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {range} from "../util/MiscUtil";
import {mkBarePlayPiece, mkCommittedPlayPiece, findFilledSegmentBoundary, mkDeadPlayPiece} from './PlayPiece';
import * as Piece from './Piece';
import {mkPoint} from './Point';
import {mkMatrixFromCoordinates} from './Matrix';
import {disconnectedWordError, noMoveError, multiplePlayLinesError, incompleteWordError} from "./GameError";

export const mkEmptyBoard = function(dimension) {
  let matrix = mkMatrixFromCoordinates(dimension, function(row, col) {
    return mkBarePlayPiece(mkPoint(row, col));
  });
  return mkBoard(matrix);
};

export const mkBoard = function(matrix) {

  let _matrix = matrix;
  let _dimension = matrix.dimension;
  let _center = parseInt(_dimension/2);

  const inBounds = function(index) {
    return index >= 0 && index < _dimension;
  };

  const sum = function(array) {
    return array.reduce(function(sum, element) {
      return sum + element;
    }, 0);
  };

  // const centerPoint = mkPoint(_center, _center);

  return {

    get dimension() { return _dimension; },
    get matrix() { return _matrix; },

    rows: function() {
      return _matrix.rows();
    },

    cols: function() {
      return _matrix.cols();
    },

    numMoves: function () {
      return _matrix.reduce(function (count, playPiece) {
        let num = count;
        if (playPiece.moved)
          num += 1;
        return num;
      }, 0);
    },

    isEmpty: function () {
      return _matrix.every(function (playPiece) {return playPiece.isFree()});
    },

    playPieces: function() {
      return _matrix.linearize().filter(function(playPiece) {
        return playPiece.hasRealPiece();
      })
    },

    hasCommittedPlays: function () {
      return _matrix.some(function (playPiece) {return playPiece.isOriginal()});
    },

    setPlayPiece: function(playPiece) {
      let $matrix = _matrix.setElement(playPiece.point, playPiece);
      return mkBoard($matrix);
    },

    getPlayPiece: function(point) {
      return _matrix.getElement(point);
    },

    getUserMovePlayPieces: function() {
      return _matrix.reduce(function(playPieces, playPiece) {
        if (playPiece.moved)
          playPieces.push(playPiece);
        return playPieces;
      }, []);
    },

    isMovedPiece(piece) {
      let movePlayPieces = this.getUserMovePlayPieces();
      let isMoved = movePlayPieces.some(it => Piece.eq(it.piece, piece));
      return isMoved;
    },

    commitUserMoves: function() {
      let playPieces = this.getUserMovePlayPieces();
      // TODO. Clone the board just once and change all play pieces. Optimization.
      let $board = this;
      playPieces.forEach(playPiece => {
        $board = $board.setPlayPiece(playPiece.setCommitted());
      });
      return $board;
    },

    rollbackUserMoves: function() {
      let $board = this;
      let playPieces = this.getUserMovePlayPieces();
      playPieces.forEach(playPiece => {
        $board = $board.setPlayPiece(mkBarePlayPiece(playPiece.point));
      });
      return $board;
    },

    findPiece(piece) {
      return _matrix.find(playPiece => Piece.eq(piece, playPiece.piece));
    },

    setDeadPoints: function(points) {
      let $board = this;
      points.forEach(point => {
        $board = $board.setPlayPiece(mkDeadPlayPiece(point));
      });
      return $board;
    },

    commitMachineMoves: function(moveGridPieces) {
      let $board = this;
      moveGridPieces.forEach(move => {
        $board = $board.setPlayPiece(mkCommittedPlayPiece(move.piece, move.point));
      });
      return $board;
    },

    isFree: function(point) {
      return this.getPlayPiece(point).isFree();
    },

    isDead: function(point) {
      return this.getPlayPiece(point).isDead();
    },

    isMoved: function(point) {
      return this.getPlayPiece(point).moved;
    },

    isOriginal: function(point) {
      return this.getPlayPiece(point).isOriginal();
    },

    /**
     * Is a move legal for the current state of the board?
     *
     * @param point Trying to move to this position.
     */
    legalMove: function(point) {
      return this.isFree(point);
    },

    /**
     * Get the play pieces for the supposedly completed play.
     * If the play is incomplete or illegal, throw an appropriate error.
     */
    completedPlayPieces() {
      let playRowsData = this.playLinesData("X");
      let playColsData = this.playLinesData("Y");

      let numPlayRows = playRowsData.length;
      let numPlayCols = playColsData.length;

      if (numPlayRows === 0 || numPlayCols === 0)
        throw noMoveError;

      if (numPlayRows > 1 && numPlayCols > 1)
        throw multiplePlayLinesError;

      let playLineData = undefined;
      let playStrip = undefined;

      if (numPlayRows === 1 && numPlayCols === 1)
        ({playLineData, playStrip} =
          this.determineSingleMovePlayLine(playRowsData[0], playColsData[0]));
      else {
        // Play line is the unique line in a given direction that contains all the moves.
        playLineData = numPlayRows === 1 ? playRowsData[0] : playColsData[0];
        playStrip = this.getPlayStrip(playLineData);
      }

      // let {axis, lineNumber} = playLineData;
      let {numMoves} = this.lineMoveInfo(playLineData);

      // The very first play is unrestricted.
      if (!this.hasCommittedPlays())
        return playStrip;

      let hasAnchor = playStrip.length - numMoves > 0;
      if (hasAnchor)
        return playStrip;

      throw disconnectedWordError;
    },

    /**
     * Get lines in a given direction that contain moves: the play lines.
     *
     * @param axis The direction of the lines.
     */
    playLinesData(axis) {
      let lines = axis === "X" ? this.rows() : this.cols();
      let lineNumbers = range(_dimension);
      let linesData = lineNumbers.map(lineNumber => {
        let line = lines[lineNumber];
        let hasMoves = line.some(playPiece => playPiece.moved);
        return { axis, lineNumber, line, hasMoves};
      });
      return linesData.filter(_ => _.hasMoves);
    },

    /**
     * Get information about the moves in a given line.
     * @param playLineData Includes the line number and the line.
     */
    lineMoveInfo(playLineData) {
      let {lineNumber, line} = playLineData;
      let firstMoveIndex = undefined;
      let lastMoveIndex = undefined;
      let hasCenterMove = false;
      let numMoves = 0;
      // TODO. Center is no longer relevant. Remove center processing.
      let center = Math.floor(_dimension / 2);

      for (let i = 0; i < _dimension; i++) {
        if (!line[i].moved)
          continue;
        if (lineNumber === center && i === center)
          hasCenterMove = true;
        if (firstMoveIndex === undefined)
          firstMoveIndex = i;
        lastMoveIndex = i;
        numMoves++;
      }

      if (numMoves === 0)
        throw {
          name: "illegal state",
          message: `line ${lineNumber} was expected to have moves but contains none`
        };

      let interMoveFreeSlots = 0; // Empty or dead slots in-between moves.
      let interMoveDeadSlots = 0; // Dead slots in-between moves.

      for (let i = firstMoveIndex + 1; i <= lastMoveIndex - 1; i++) {
        if (this.isFree(line[i].point))
          interMoveFreeSlots += 1;
        if (this.isDead(line[i].point))
          interMoveDeadSlots += 1;
      }

      let isContiguous = interMoveFreeSlots === 0 && interMoveDeadSlots === 0;

      return {
        numMoves, firstMoveIndex, lastMoveIndex, isContiguous, hasCenterMove
      };
    },

    /**
     * Get the strip of a line that contains the entire word play,
     * including moves and existing tiles. Returns the ordered
     * list of tiles (as play pieces).
     *
     * @param playLineData Provides the line.
     *
     */
    getPlayStrip(playLineData) {
      let {line} = playLineData;
      let {firstMoveIndex, lastMoveIndex, isContiguous} =
        this.lineMoveInfo(playLineData);

      if (!isContiguous)
        throw incompleteWordError;

      let beginIndex = this.extendsTo(line, firstMoveIndex, -1);
      let endIndex = this.extendsTo(line, lastMoveIndex, +1);

      let playStrip = line.slice(beginIndex, endIndex + 1); // Slice is right-exclusive.
      return playStrip;
    },

    /**
     * In case there is just one move in the play being committed,
     * determine whether the principle axis of the play is horizontal
     * or vertical and get the strip of the play. The principle axis
     * is one in which the move is connected to an existing tile.
     *
     * @param rowLineData Data about the unique play row.
     * @param colLineData Data about the unique play column.
     */
    determineSingleMovePlayLine(rowLineData, colLineData) {
      let rowPlayStrip = this.getPlayStrip(rowLineData);
      let colPlayStrip = this.getPlayStrip(colLineData);

      // The very first play is allowed to include just one letter (e.g., "a").
      // Otherwise a single letter play must be disconnected.
      if (rowPlayStrip.length === 1 && colPlayStrip.length === 1 && this.hasCommittedPlays())
        throw disconnectedWordError;

      let playLineData = rowPlayStrip.length > 1 ? rowLineData : colLineData;
      let playStrip = rowPlayStrip.length > 1 ? rowPlayStrip : colPlayStrip;

      return { playLineData, playStrip };
    },

    /**
     * Get an ordered list of contact points to an adjacent line for a given play.
     */
    // parallelContacts(axis, lineNumber, playStrip, direction) {
    //   const response = (contactPoints, contiguous) =>
    //     {return {contactPoints, contiguous}};
    //
    //   const responseNone = response([], false);
    //
    //   let adjLineNumber = lineNumber + direction;
    //   if (adjLineNumber < 0 || adjLineNumber >= _dimension)
    //     return responseNone;
    //
    //   let that = this;
    //   let contactPoints = playStrip
    //     .map(playPiece => {
    //       let point = playPiece.point;
    //       let r = axis === "X" ? adjLineNumber : point.row;
    //       let c = axis === "Y" ? adjLineNumber : point.col;
    //       return mkPoint(r, c);
    //     })
    //     .filter(p => !that.isFree(p));
    //
    //   if (contactPoints.length === 0)
    //     return responseNone;
    //
    //   let first = contactPoints[0];
    //   let last = contactPoints[contactPoints.length - 1];
    //
    //   let begin = axis === "X" ? first.col : first.row;
    //   let end = axis === "X" ? last.col : last.row;
    //
    //   let contiguous = (end - begin + 1) === contactPoints.length;
    //   return response(contactPoints, contiguous);
    // },

    // TODO. Remove. Replace with the inner call.
    extendsTo(playPieces, index, direction) {
      return findFilledSegmentBoundary(playPieces, index, direction);
    }
  };
};