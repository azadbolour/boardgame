/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import * as Board from './Board';
import * as Point from './Point';
import * as Tray from './Tray';
import * as PlayPiece from './PlayPiece';
import {mkMovePlayPiece, mkCommittedPlayPiece} from './PlayPiece';

export const USER_INDEX = 0;
export const MACHINE_INDEX = 1;

const EMPTY_GAME_ID = "emptyGame";

const RUN_STATE = {
  PRE_START: "pre-start",
  RUNNING: "running",
  FINISHED: "finished",
  KILLED: "killed"
};

export const mkEmptyGame = function(gameParams) {
  const board = Board.mkEmptyBoard(gameParams.dimension);
  const tray = Tray.mkEmptyTray(gameParams.trayCapacity);
  const score = [0, 0];
  return mkGame(gameParams, EMPTY_GAME_ID, board, tray, score, RUN_STATE.PRE_START);
};

export const mkGame = function(gameParams, gameId, board, tray, score, runState = RUN_STATE.RUNNING) {
  let _gameParams = gameParams;
  let _gameId = gameId;
  let _board = board;
  let _tray = tray;
  let _dimension = gameParams.dimension;
  let _squarePixels = gameParams.squarePixels;
  let _trayCapacity = gameParams.trayCapacity;
  let _score = score;
  let _runState = runState;

  let updateScore = function(playerIndex, playedPieces) {
    let updatedScore = _score.slice();
    updatedScore[playerIndex] += playedPieces.length;
    return updatedScore;
  };

  // Need a revert here - so that applyBoardMove can be implemented as a revert + a tray move.

  return {
    get gameParams() { return _gameParams; },
    get gameId() { return _gameId; },
    get board() { return _board; },
    get tray() { return _tray; },
    get dimension() { return _dimension; },
    get squarePixels() { return _squarePixels; },
    get trayCapacity() { return _trayCapacity; },
    get score() { return _score.slice(); },
    get runState() {return _runState; },

    running: function() {
      return _runState === RUN_STATE.RUNNING;
    },

    terminated: function() {
      return !this.running();
    },

    kill: function() {
      let $game = mkGame(_gameParams, _gameId, _board, _tray, _score, RUN_STATE.KILLED);
      return $game;
    },

    // TODO. Move canMove function to TrayComponent and BoardComponent.
    // It is a user interaction issue and belongs to components.
    canMovePiece: function(piece) {
      if (_tray.findIndexByPieceId(piece.pieceId) >= 0)
        return true;
      return _board.isMovedPiece(piece);
    },

    // TODO. Better to return flag indicating move was successful, as well as mutated game.

    applyUserMove: function(move) {
      const { piece, point } = move;
      if (!this.legalMove(piece, point)) {
        console.log(`attempt to apply illegal move ${stringify(move)} - ignored`);
        return this;
      }

      const trayIndex = _tray.findIndexByPieceId(piece.pieceId);
      const sourcePoint = _board.findPiece(piece);

      const isFromTray = trayIndex >= 0;
      const isFromBoard = sourcePoint !== undefined;

      // console.log(`isFromTray: ${isFromTray}, isFromBoard: ${isFromBoard}`);

      if (isFromTray && isFromBoard)
        throw {
          name: "illegal state",
          message: `piece ${stringify(piece)} belongs to both the tray and the board`
        };

      if (isFromTray)
        return this.applyTrayMove(move);
      else
        return this.applyBoardMove(move);
    },

    applyBoardMove: function(move) {
      const { piece, point } = move;
      let sourcePoint = _board.findPiece(piece);
      let $game = this.revertMove(piece, sourcePoint);
      return $game.applyTrayMove(move);
    },

    applyTrayMove: function(move) {
      const { piece, point } = move;
      let playPiece = mkMovePlayPiece(piece, point);
      let $tray = _tray.removePiece(piece.pieceId);
      let $board = _board.setPlayPiece(playPiece);
      let $game = mkGame(_gameParams, _gameId, $board, $tray, _score);
      return $game;
    },

    getUserMovePlayPieces: function() {
      return _board.getUserMovePlayPieces();
    },

    getCompletedPlayPieces: function() {
      return _board.completedPlayPieces();
    },

    commitUserMoves: function(replacementPieces) {
      let $tray = _tray.addPieces(replacementPieces);
      let playedPieces = this.getUserMovePlayPieces().map(playPiece => playPiece.piece);
      let $score = updateScore(USER_INDEX, playedPieces);
      let $board = _board.commitUserMoves();
      let $game = mkGame(_gameParams, _gameId, $board, $tray, $score);
      return $game;
    },

    commitMachineMoves: function(moveGridPieces) {
      let $board = _board.commitMachineMoves(moveGridPieces);
      let playedPieces = moveGridPieces.map(move => move.piece);
      let $score = updateScore(MACHINE_INDEX, playedPieces);
      return mkGame(_gameParams, _gameId, $board, _tray, $score);
    },

    end: function() {
      let $game = mkGame(_gameParams, _gameId, _board, _tray, _score, RUN_STATE.FINISHED);
      return $game;
    },

    revertPlay: function() {
      let movedPlayPieces = this.getUserMovePlayPieces();
      let movedTrayPieces = movedPlayPieces.map(playPiece => playPiece.piece)
      let $board = _board.rollbackUserMoves();
      let $tray = _tray.addPieces(movedTrayPieces);
      let $game = mkGame(_gameParams, _gameId, $board, $tray, _score);
      return $game;
    },

    numPiecesInPlay: function() {
      return this.getUserMovePlayPieces().length;
    },

    revertMove: function(piece) {
      let point = _board.findPiece(piece);
      if (point === undefined) {
        console.log(`attempt to revert move of piece: ${stringify(piece)} which does not belong to the board - ignored`);
        return;
      }
      let barePlayPiece = PlayPiece.mkBarePlayPiece(point);
      let $board = _board.setPlayPiece(barePlayPiece);
      let $tray = _tray.addPiece(piece);
      let $game = mkGame(_gameParams, _gameId, $board, $tray, _score);
      return $game;
    },

    legalMove: function(piece, point) {
      let onTray = _tray.findIndexByPieceId(piece.pieceId) >= 0;
      let onBoardPoint = _board.findPiece(piece);
      let onBoard = onBoardPoint !== undefined;

      if (onTray && onBoard)
        throw {
          name: "illegal state",
          message: `piece ${stringify(piece)} on tray and on board at the same time`
        };

      // Intra-board move is equivalent to a revert followed by a tray move.

      let testGame = this;
      if (onBoard)
        testGame = this.revertMove(piece, onBoardPoint);
      let testBoard = testGame.board;
      let legal = testBoard.legalMove(piece, point, testGame.tray.size());
      return legal;
    },

    replaceTrayPiece: function(replacedPieceId, replacementPiece) {
      let $tray = _tray.replacePiece(replacedPieceId, replacementPiece);
      return mkGame(_gameParams, _gameId, _board, $tray, _score);
    }
  };
};