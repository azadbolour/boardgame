/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import * as Board from './Board';
import * as Point from './Point';
import * as Tray from './Tray';
import * as PlayPiece from './PlayPiece';
import {mkMovePlayPiece, mkCommittedPlayPiece} from './PlayPiece';
// import {mkMultiplierGrid} from "./ScoreMultiplier";
import * as PointValue from './PointValue';

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
  const valueFactory = PointValue.mkValueFactory(gameParams.dimension);
  const pointValues = valueFactory.mkEmptyValueGrid();
  const score = [0, 0];
  return mkGame(gameParams, EMPTY_GAME_ID, board, tray, pointValues, score, [], RUN_STATE.PRE_START);
};

export const mkGame = function(gameParams, gameId, board, tray, pointValues, score, machineMoves = [], runState = RUN_STATE.RUNNING) {
  let _gameParams = gameParams;
  let _gameId = gameId;
  let _board = board;
  let _tray = tray;
  let _dimension = gameParams.dimension;
  let _squarePixels = gameParams.squarePixels;
  let _trayCapacity = gameParams.trayCapacity;
  let _pointValues = pointValues;
  let _score = score;
  let _machineMoves = machineMoves;
  let _runState = runState;

  let updateScore = function(playerIndex, playScore) {
    let updatedScore = _score.slice();
    // updatedScore[playerIndex] += playedPieces.length;
    updatedScore[playerIndex] += playScore;
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
    get pointValues() { return _pointValues; },
    get score() { return _score.slice(); },
    get machineMoves() { return _machineMoves.slice(); },
    get runState() {return _runState; },

    isEmpty: function() {
      return _gameId === EMPTY_GAME_ID;
    },

    isFilled: function() {
      return _board.isFull();
    },

    running: function() {
      return _runState === RUN_STATE.RUNNING;
    },

    terminated: function() {
      return !this.running();
    },

    kill: function() {
      let $game = mkGame(_gameParams, _gameId, _board, _tray, _pointValues, _score, [], RUN_STATE.KILLED);
      return $game;
    },

    // TODO. Move canMove function to TrayComponent and BoardComponent.
    // It is a user interaction issue and belongs to components.
    canMovePiece: function(piece) {
      if (_tray.findIndexByPieceId(piece.id) >= 0)
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

      const trayIndex = _tray.findIndexByPieceId(piece.id);
      const sourcePlayPiece = _board.findPiece(piece);

      const isFromTray = trayIndex >= 0;
      const isFromBoard = sourcePlayPiece !== undefined;

      // console.log(`applyUserMove - isFromTray: ${isFromTray}, isFromBoard: ${isFromBoard}`);
      // this.logGameState();

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
      // let sourcePoint = _board.findPiece(piece);
      let $game = this.revertMove(piece);
      return $game.applyTrayMove(move);
    },

    applyTrayMove: function(move) {
      const { piece, point } = move;
      // console.log(`applying tray move: ${stringify(move)}`);
      let playPiece = mkMovePlayPiece(piece, point);
      let $tray = _tray.removePiece(piece.id);
      let $board = _board.setPlayPiece(playPiece);
      let $game = mkGame(_gameParams, _gameId, $board, $tray, _pointValues, _score);
      // console.log(`tray move applied - new game state`);
      // $game.logGameState();
      return $game;
    },

    getUserMovePlayPieces: function() {
      return _board.getUserMovePlayPieces();
    },

    /**
     * Throws exception if play is illegal.
     */
    getCompletedPlayPieces: function() {
      return _board.completedPlayPieces(); // Throws.
    },

    commitUserMoves: function(playScore, replacementPieces, deadPoints) {
      let $tray = _tray.addPieces(replacementPieces);
      let playedPieces = this.getUserMovePlayPieces().map(playPiece => playPiece.piece);
      // let $score = updateScore(USER_INDEX, playedPieces);
      let $score = updateScore(USER_INDEX, playScore);
      let $board = _board.commitUserMoves();
      let $game = mkGame(_gameParams, _gameId, $board, $tray, _pointValues, $score);
      $game = $game.setDeadPoints(deadPoints);
      return $game;
    },

    commitMachineMoves: function(playScore, moveGridPieces, deadPoints) {
      let $board = _board.commitMachineMoves(moveGridPieces);
      let playedPieces = moveGridPieces.map(move => move.piece);
      // let $score = updateScore(MACHINE_INDEX, playedPieces);
      let $score = updateScore(MACHINE_INDEX, playScore);
      let $game = mkGame(_gameParams, _gameId, $board, _tray, _pointValues, $score, moveGridPieces);
      $game = $game.setDeadPoints(deadPoints);
      return $game;
    },

    setDeadPoints: function(points) {
      let $board = _board.setDeadPoints(points);
      return mkGame(_gameParams, _gameId, $board, _tray, _pointValues, _score, _machineMoves);
    },

    end: function() {
      let $game = mkGame(_gameParams, _gameId, _board, _tray, _pointValues, _score, [], RUN_STATE.FINISHED);
      return $game;
    },

    revertPlay: function() {
      let movedPlayPieces = this.getUserMovePlayPieces();
      let movedTrayPieces = movedPlayPieces.map(playPiece => playPiece.piece)
      let $board = _board.rollbackUserMoves();
      let $tray = _tray.addPieces(movedTrayPieces);
      let $game = mkGame(_gameParams, _gameId, $board, $tray, _pointValues, _score);
      return $game;
    },

    numPiecesInPlay: function() {
      return this.getUserMovePlayPieces().length;
    },

    revertMove: function(piece) {
      let sourcePlayPiece = _board.findPiece(piece);
      let point = sourcePlayPiece.point;

      if (point === undefined) {
        console.log(`attempt to revert move of piece: ${stringify(piece)} which does not belong to the board - ignored`);
        return;
      }
      let barePlayPiece = PlayPiece.mkBarePlayPiece(point);
      let $board = _board.setPlayPiece(barePlayPiece);
      let $tray = _tray.addPiece(piece);
      let $game = mkGame(_gameParams, _gameId, $board, $tray, _pointValues, _score);
      return $game;
    },

    legalMove: function(piece, point) {
      let onTray = _tray.findIndexByPieceId(piece.id) >= 0;
      let sourcePlayPiece = _board.findPiece(piece);
      let onBoard = sourcePlayPiece !== undefined;

      if (onTray && onBoard) {
        console.log(`move error: piece: ${stringify(piece)}, point: ${stringify(point)}, source play piece: ${stringify(sourcePlayPiece)}`)
        this.logGameState();
        console.trace();
        throw {
          name: "illegal state",
          message: `piece ${stringify(piece)} on tray and on board at the same time`
        };
      }

      // Cannot move a committed piece.
      if (onBoard && sourcePlayPiece.isOriginal())
        return false;

      // Intra-board move is equivalent to a revert followed by a tray move.

      let testGame = this;
      if (onBoard)
        testGame = this.revertMove(piece);
      let testBoard = testGame.board;
      let legal = testBoard.legalMove(point);
      return legal;
    },

    replaceTrayPiece: function(replacedPieceId, replacementPiece) {
      let $tray = _tray.replacePiece(replacedPieceId, replacementPiece);
      return mkGame(_gameParams, _gameId, _board, $tray, _pointValues, _score);
    },

    logGameState: function() {
      let playPieces = _board.playPieces();
      console.log("-- The Board --")
      playPieces.forEach(function(pp) {
        console.log(`piece: ${stringify(pp.piece)}, point: ${stringify(pp.point)}. moved: ${pp.moved}`);
      });
      console.log("-- The Tray --");
      _tray.pieces.forEach(function(p) {
        console.log(`${stringify(p)}`);
      });
    }
  };
};