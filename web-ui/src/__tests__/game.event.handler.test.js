/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

'use strict';

import {stringify} from "../util/Logger";

import actions from '../event/GameActions';
import GameParams from "../domain/GameParams";
import {mkGameEventHandler} from '../event/GameEventHandler';
import * as Piece from "../domain/Piece";
import {mkPoint} from "../domain/Point";
import {mkGridPiece} from "../domain/GridPiece";
import GameService from "../service/GameService"
import {gameDispatcher} from '../event/GameDispatcher';

// TODO. Don't know how you are supposed to wait for a promise
// TODO. to be fulfilled in a jest test. What is the model?

test('generate events to exercise game transitions', done => {
  let gameParams = GameParams.defaultParams();
  let dimension = gameParams.dimension;
  let mid = Math.floor(dimension / 2);
  let gameService = new GameService(gameParams);
  let handler = mkGameEventHandler(gameService);

  // let moveDest = mkPoint(1, 1);
  let moveDest = mkPoint(mid - 1, mid);
  let movingPiece = undefined;

  let endCallback = function(stage, game, status, auxGameData) {
    console.log("end callback");
    // This gets more complicated than it is worth for now.
    // Since committing also internally involves getting machine play.

    // let playPiece = game.board.rows()[1][1];
    // expect(Piece.eq(playPiece.piece, movingPiece)).toBe(true);
    // expect(playPiece.moved).toBe(false);

    done(); // Tell jest it can now exit.
  };

  let moveCallback = function(stage, game, status, auxGameData) {
    let playPieces = game.getUserMovePlayPieces();
    expect(playPieces.length).toBe(1);
    setTimeout(function() {
      console.log("move callback");
      handler.unregisterChangeObserver(moveCallback);
      handler.registerChangeObserver(endCallback);
      actions.commitPlay();
    }, 20);
  };

  let startCallback = function(stage, game, status, auxGameData) {
    setTimeout(function() {
      console.log("start callback");
      handler.unregisterChangeObserver(startCallback);
      handler.registerChangeObserver(moveCallback);
      movingPiece = game.tray.pieces[0];
      let move = mkGridPiece(movingPiece, moveDest);
      actions.move(move);
    }, 20);
  };

  gameDispatcher.register(handler.dispatchHandler);
  handler.registerChangeObserver(startCallback);
  actions.start(gameParams);
});

