/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {mkPiece} from "../domain/Piece";
import * as Piece from "../domain/Piece";
import {mkGame} from "../domain/Game";
import GameParams from "../domain/GameParams";
import {mkEmptyBoard} from "../domain/Board";
import {mkTray} from "../domain/Tray";
import {mkPoint} from "../domain/Point";
import {mkGridPiece} from "../domain/GridPiece";

const LARGE = 1000000;

const testUtil = {
  randomPiece: function() {
    let value = Piece.randomLetter();
    let id = String(Math.floor(Math.random() * LARGE));
    return mkPiece(value, id);
  },

  randomPieces: function(numPieces) {
    let pieces = [];
    for (let i = 0; i < numPieces; i++)
      pieces.push(testUtil.randomPiece());
    return pieces;
  },

  defaultGame: function() {
    let params = GameParams.defaultParams();
    let board = mkEmptyBoard(params.dimension);
    let tray = mkTray(params.trayCapacity, testUtil.randomPieces(params.trayCapacity));
    return mkGame(params, 1, board, tray, [0, 0]);
  },

  // addInitialPlayToGame: function(game) {
  //   let mid = Math.floor(game.dimension / 2);
  //   let leftMove = mkGridPiece(game.tray.pieces[0], mkPoint(mid, mid - 1));
  //   let $game = game.applyUserMove(leftMove);
  //   let rightMove = mkGridPiece($game.tray.pieces[0], mkPoint(mid, mid + 1));
  //   $game = $game.applyUserMove(rightMove);
  //   return $game;
  // }
};

export default testUtil;

