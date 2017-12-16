/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import * as Point from './Point';
import {checkArray, checkArrayIndex, checkCapacityOverflow} from "../util/MiscUtil";
import {stringify} from "../util/Logger";
import {range} from "../util/MiscUtil";
import {mkBarePlayPiece, mkMovePlayPiece, mkCommittedPlayPiece, findFilledSegmentBoundary} from './PlayPiece';
import * as PlayPiece from './PlayPiece';
import * as Piece from './Piece';
import {mkPoint} from './Point';
import {mkMatrixFromCoordinates} from './Matrix';

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
      const movePlayPieces = this.getUserMovePlayPieces();
      const isMoved = movePlayPieces.some(it => Piece.eq(it.piece, piece));
      return isMoved;
    },

    commitUserMoves: function() {
      const playPieces = this.getUserMovePlayPieces();
      // TODO. Clone the board just once and change all play pieces. Optimization.
      let $board = this;
      playPieces.forEach(playPiece => {
        $board = $board.setPlayPiece(playPiece.setCommitted());
      });
      return $board;
    },

    rollbackUserMoves: function() {
      let $board = this;
      const playPieces = this.getUserMovePlayPieces();
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
     * @param point Trying to move to this position.
     * @param piece Moving this piece.
     * @param numTrayPieces Number of tray pieces left after making this move.
     *                      Need enough of them to fill minimum gaps left by this move.
     * @returns {boolean}
     */
    legalMove: function(piece, point, numTrayPieces) {
      if (!this.isFree(point))
        return false;
      // For now restrict the very first move to be to the center point.
      if (this.isEmpty())
        return Point.eq(point, centerPoint);

      // Move the piece to the board on a trial basis.
      let testBoard = this.setPlayPiece(mkMovePlayPiece(piece, point));
      let testTrayPieces = numTrayPieces - 1; // Trial tray has lost the moved piece.
      let movesInfoX = testBoard.linesMoveInfo("X");
      let movesInfoY = testBoard.linesMoveInfo("Y");

      const hasUniqueLegalLine = function(movesInfo) {
        return movesInfo.length === 1 && testBoard.isCompletable(movesInfo[0], testTrayPieces)
      };
      return hasUniqueLegalLine(movesInfoX) || hasUniqueLegalLine(movesInfoY);
    },

    isCompletable(info, numTrayPieces) {
      let { axis, lineNumber, numMoves, firstMoveIndex, lastMoveIndex,
        nearestLeftNeighbor, nearestRightNeighbor, interMoveFreeSlots, hasInterMoveAnchor } = info;

      if (numMoves === 0)
        return false;
      if (hasInterMoveAnchor)
        return interMoveFreeSlots <= numTrayPieces;

      let minFreeSlots = interMoveFreeSlots;

      // Line of the very first play has current moves only - no other pieces.
      // So ensure that tray pieces cover inter-move slots.
      if (!this.hasCommittedPlays())
        return minFreeSlots <= numTrayPieces;

      // Not the very first play and no intern-move anchor.
      // So must have an anchor to the right or to the left.
      if (nearestLeftNeighbor === undefined && nearestRightNeighbor === undefined)
        return false; // Nothing to connect to.

      let minSlotsToFill = function() {
        let leftSlotsToConnect = firstMoveIndex - nearestLeftNeighbor - 1; // May be NaN. OK.
        let rightSlotsToConnect = nearestRightNeighbor - lastMoveIndex - 1; // ditto

        if (nearestLeftNeighbor === undefined)
          minFreeSlots += rightSlotsToConnect;
        else if (nearestRightNeighbor === undefined)
          minFreeSlots += leftSlotsToConnect;
        else minFreeSlots += Math.min(leftSlotsToConnect, rightSlotsToConnect);

        return minFreeSlots;
      };

      return minSlotsToFill() <= numTrayPieces;
    },

    /**
     * For those lines that contain at least one move,
     * get the data needed to check legality.
     */
    linesMoveInfo(axis) {
      const that = this;
      return range(this.dimension)
        .map(lineNumber => that.lineMoveInfo(axis, lineNumber))
        .filter(function(info) {
          return info !== undefined;
        });
    },

    // linesMoveInfo(axis, playPieceLines) {
    //   const that = this;
    //   return playPieceLines
    //     .map(function(line) {
    //       return that.lineMoveInfo(axis, line);
    //     })
    //     .filter(function(info) {
    //       return info !== undefined;
    //     });
    // },

    lineMoveInfo: function(axis, lineNumber) {
      let line = (axis === "X" ? this.rows() : this.cols())[lineNumber];
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
        return undefined;

      let interMoveFreeSlots = 0; // Empty slots in-between moves.
      for (let i = firstMoveIndex + 1; i <= lastMoveIndex - 1; i++)
        if (this.isFree(line[i].point))
          interMoveFreeSlots += 1;

      let interMoveOriginalSlots = numMoves === 1 ? 0 :
        (lastMoveIndex - firstMoveIndex - 1) - (numMoves - 2) - interMoveFreeSlots;

      let nearLeft = this.nearestOriginalNeighbor(line, firstMoveIndex, -1);
      let nearRight = this.nearestOriginalNeighbor(line, lastMoveIndex, 1);

      return {
        axis: axis,
        lineNumber: lineNumber,
        numMoves: numMoves,
        firstMoveIndex: firstMoveIndex,
        lastMoveIndex: lastMoveIndex,
        nearestLeftNeighbor: nearLeft,
        nearestRightNeighbor: nearRight,
        interMoveFreeSlots: interMoveFreeSlots,
        hasInterMoveAnchor: interMoveOriginalSlots > 0,
        hasCenterMove: hasCenterMove
      }
    },

    nearestOriginalNeighbor: function(playPieces, index, direction) {
      for (let i = index + direction; inBounds(i); i = i + direction)
        if (playPieces[i].isOriginal())
          return i;
      return undefined;
    },

    /**
     * If a play strip is completed return the completed strip,
     * otherwise return an empty array.
     */
    completedPlayPieces() {
      let lineInfos = this.playLineInfo();

      if (lineInfos.length === 0)
        return [];
      else if (lineInfos.length === 1)
        return this.completedPlayPiecesForOneLine(lineInfos[0]);
      else {
        let completed0 = this.completedPlayPiecesForOneLine(lineInfos[0]);
        if (completed0.length > 0)
          return completed0;
        else
          return this.completedPlayPiecesForOneLine(lineInfos[1]);
      }

      // let [axis, lineNumber] = [lineInfo.axis, lineInfo.lineNumber];
      // let line = (axis === "X") ? this.rows()[lineNumber] : this.cols()[lineNumber];
      //
      // // No original pieces. Should not happen. Check for good measure.
      // let numOriginalPieces = sum(line.map(pp => pp.isOriginal() ? 1 : 0));
      // if (numOriginalPieces === 0)
      //   return [];
      //
      // // Gaps remain - play is incomplete.
      // if (lineInfo.interMoveFreeSlots > 0)
      //   return [];
      //
      // // Inter-move slots are filled. Find extent of play to the right and left of moves.
      // let leftIndex = this.extendsTo(line, lineInfo.firstMoveIndex, -1);
      // let rightIndex = this.extendsTo(line, lineInfo.lastMoveIndex, +1);
      //
      // let strip = line.slice(leftIndex, rightIndex + 1); // Slice is right-exclusive.
      // return strip;
    },

    completedPlayPiecesForOneLine(lineInfo) {
      let [axis, lineNumber] = [lineInfo.axis, lineInfo.lineNumber];
      let line = (axis === "X") ? this.rows()[lineNumber] : this.cols()[lineNumber];

      // No original pieces in play line - it can happen only for the first play.
      let numOriginalPieces = sum(line.map(pp => pp.isOriginal() ? 1 : 0));
      if (this.hasCommittedPlays() && numOriginalPieces === 0)
        return [];

      // Gaps remain - play is incomplete.
      if (lineInfo.interMoveFreeSlots > 0)
        return [];

      // Inter-move slots are filled. Find extent of play to the right and left of moves.
      let leftIndex = this.extendsTo(line, lineInfo.firstMoveIndex, -1);
      let rightIndex = this.extendsTo(line, lineInfo.lastMoveIndex, +1);

      let strip = line.slice(leftIndex, rightIndex + 1); // Slice is right-exclusive.
      numOriginalPieces = sum(strip.map(pp => pp.isOriginal() ? 1 : 0));
      // Not the first play and has no anchor.
      if (this.hasCommittedPlays() && numOriginalPieces === 0)
        return [];
      return strip;
    },

    /**
     * Get info on possible play lines.
     */
    playLineInfo() {
      let hasAnchor = function(lineInfo) {
        return lineInfo.hasInterMoveAnchor
          || lineInfo.nearestLeftNeighbor !== undefined
          || lineInfo.nearestRightNeighbor !== undefined;
      };

      let isCentered = function(lineInfo) {
        return lineInfo.hasCenterMove;
      };

      // If it is the first play, it must have a center move which acts as an anchor.
      let isPlayLine = this.hasCommittedPlays() ? hasAnchor : isCentered;

      let playRowsInfo = this.linesMoveInfo("X")
      playRowsInfo = playRowsInfo.filter(isPlayLine);
      let playColsInfo = this.linesMoveInfo("Y")
      playColsInfo = playColsInfo.filter(isPlayLine);

      let numPlayRows = playRowsInfo.length;
      let numPlayCols = playColsInfo.length;

      // No play lines at all.
      if (numPlayRows === 0 && numPlayCols === 0)
        return [];

      // The principle play defines a single word in a single line in the principle direction.
      // But that word may define multiple plays in the cross direction.

      if (numPlayRows > 1 && numPlayCols > 1)
        throw {
          name: "illegal state",
          message: "found multiple play in each direction - not allowed"
        };

      // A single move may have caused 2 legitimate plays in cross directions.
      // Just choose the first one as the principle direction.

      if (numPlayRows === 1 && numPlayCols === 1)
        return [playRowsInfo[0], playColsInfo[0]];

      let movesInfo = numPlayRows === 1 ? playRowsInfo[0] : playColsInfo[0];
      return [movesInfo];
    },

    // TODO. Remove. Replace with the inner call.
    extendsTo(playPieces, index, direction) {
      return findFilledSegmentBoundary(playPieces, index, direction);
    }
    //   let to = index;
    //   for (let i = index + direction; inBounds(i); i = i + direction)
    //     if (!playPieces[i].isFree()) {
    //       to = i;
    //       continue;
    //     }
    //   return to;
    // }
  };
};