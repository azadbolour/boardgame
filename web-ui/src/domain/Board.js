/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import * as Point from './Point';
import {stringify} from "../util/Logger";
import {range} from "../util/MiscUtil";
import {mkBarePlayPiece, mkMovePlayPiece, mkCommittedPlayPiece, findFilledSegmentBoundary} from './PlayPiece';
import * as PlayPiece from './PlayPiece';
import * as Piece from './Piece';
import {mkPoint} from './Point';
import {mkMatrixFromCoordinates} from './Matrix';
import * as GameError from './GameError';

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

  const centerPoint = mkPoint(_center, _center);

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
      // TODO. Optimize by changing board in place.
      playPieces.forEach(playPiece => {
        $board = $board.setPlayPiece(mkBarePlayPiece(playPiece.point));
      });
      return $board;
    },

    findPiece(piece) {
      return _matrix.find(playPiece => Piece.eq(piece, playPiece.piece));
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

    playLineData(axis, lineNumber, line) {
      return {
        axis,
        lineNumber,
        line,
        hasMoves: line.some(playPiece => playPiece.moved)
      }
    },

    lineMoveInfo(playLineData) {
      let {lineNumber, line} = playLineData;
      let firstMoveIndex = undefined;
      let lastMoveIndex = undefined;
      let hasCenterMove = false;
      let numMoves = 0;
      let center = Math.floor(_dimension / 2);
      for (let i = 0; i < _dimension; i++) {
        if (line[i].moved) {
          if (lineNumber === center && i === center)
            hasCenterMove = true;
          if (firstMoveIndex === undefined)
            firstMoveIndex = i;
          lastMoveIndex = i;
          numMoves++;
        }
      }

      if (numMoves === 0)
        throw {
          name: "illegal state",
          message: `line ${lineNumber} was expected to have moves but contains none`
        };
      let interMoveFreeSlots = 0; // Empty slots in-between moves.
      for (let i = firstMoveIndex + 1; i <= lastMoveIndex - 1; i++)
        if (this.isFree(line[i].point))
          interMoveFreeSlots += 1;

      let isContiguous = interMoveFreeSlots === 0;

      return {
        numMoves,
        firstMoveIndex,
        lastMoveIndex,
        isContiguous,
        hasCenterMove
      };
    },

    /**
     * Get the play pieces for the supposedly completed play.
     * If the play is incomplete or illegal, throw an appropriate error.
     */
    completedPlayPieces() {
      let that = this;
      let lineNumbers = range(_dimension);
      let playRowsData = lineNumbers
        .map(r => this.playLineData("X", r, that.rows()[r]))
        .filter(_ => _.hasMoves);
      let playColsData = lineNumbers
        .map(c => this.playLineData("Y", c, that.cols()[c]))
        .filter(_ => _.hasMoves);

      let numPlayRows = playRowsData.length;
      let numPlayCols = playColsData.length;
      if (numPlayRows === 0 || numPlayCols === 0)
        throw GameError.noMoveError;
      if (numPlayRows > 1 && numPlayCols > 1)
        throw GameError.multiplePlayLinesError;

      let playLineData = numPlayCols > 1 ? playRowsData[0] : playColsData[0];
      let {axis, lineNumber, line} = playLineData;
      let {numMoves, firstMoveIndex, lastMoveIndex, isContiguous, hasCenterMove} =
        this.lineMoveInfo(playLineData);

      if (!isContiguous)
        throw GameError.incompleteWordError;

      let beginIndex = this.extendsTo(line, firstMoveIndex, -1);
      let endIndex = this.extendsTo(line, lastMoveIndex, +1);

      let playStrip = line.slice(beginIndex, endIndex + 1); // Slice is right-exclusive.

      let isVeryFirstPlay = !this.hasCommittedPlays();
      if (isVeryFirstPlay) {
        if (hasCenterMove) return playStrip;
        else throw GameError.offCenterError;
      }

      let hasAnchor = playStrip.length - numMoves > 0;
      if (hasAnchor)
        return playStrip;

      // It is a parallel play. Check adjacency to a word on either side.

      let {contactPoints: prevContacts, contiguous: prevContiguous} =
        this.parallelContacts(axis, lineNumber, playStrip, -1);
      let {contactPoints: nextContacts, contiguous: nextContiguous} =
        this.parallelContacts(axis, lineNumber, playStrip, +1);

      if (prevContacts.length === 0 && nextContacts.length === 0)
        throw GameError.disconnectedWordError;

      if (!prevContiguous && !nextContiguous)
        throw GameError.noAdjacentWordError;

      return playStrip;
    },

    /**
     * Get an ordered list of contact points to an adjacent line for a given play.
     */
    parallelContacts(axis, lineNumber, playStrip, direction) {
      const response = (contactPoints, contiguous) =>
        {return {contactPoints, contiguous}};

      const responseNone = response([], false);

      let adjLineNumber = lineNumber + direction;
      if (adjLineNumber < 0 || adjLineNumber >= _dimension)
        return responseNone;

      let that = this;
      let contactPoints = playStrip
        .map(playPiece => {
          let point = playPiece.point;
          let r = axis === "X" ? adjLineNumber : point.row;
          let c = axis === "Y" ? adjLineNumber : point.col;
          return mkPoint(r, c);
        })
        .filter(p => !that.isFree(p));

      if (contactPoints.length === 0)
        return responseNone;

      let first = contactPoints[0];
      let last = contactPoints[contactPoints.length - 1];

      let begin = axis === "X" ? first.col : first.row;
      let end = axis === "X" ? last.col : last.row;

      let contiguous = (end - begin + 1) === contactPoints.length;
      return response(contactPoints, contiguous);
    },

    // TODO. Remove. Replace with the inner call.
    extendsTo(playPieces, index, direction) {
      return findFilledSegmentBoundary(playPieces, index, direction);
    }
  };
};