/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

'use strict';

// import {stringify} from "../util/Logger";

import GameParams from "../domain/GameParams";
import {mkGameHandler} from '../event/GameHandler';
// import * as Piece from "../domain/Piece";
import {mkPoint} from "../domain/Point";
import {mkPiecePoint} from "../domain/PiecePoint";
import GameService from "../service/GameService"

// TODO. Don't know how you are supposed to wait for a promise
// TODO. to be fulfilled in a jest test. What is the model?

test('generate events to exercise game transitions', done => {
  let gameParams = GameParams.mkDefaultParams();
  let dimension = gameParams.dimension;
  let mid = Math.floor(dimension / 2);
  let gameService = new GameService(gameParams);
  // let handler = mkGameEventHandler(gameService);

  const {gameEventHandler, subscribe, unsubscribe} = mkGameHandler(gameService);

  // let moveDest = mkPoint(1, 1);
  // let moveDest = mkPoint(mid - 1, mid);
  let moveDest = mkPoint(mid, mid);
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

  let moveCallback = function(gameState) {
    const game = gameState.game;
    const auxGameData = gameState.auxGameData;
    let playPieces = game.getUserMovePlayPieces();
    expect(playPieces.length).toBe(1);
    setTimeout(function() {
      console.log("move callback");
      unsubscribe(moveCallback);
      subscribe(endCallback);
      gameEventHandler.commitPlayAndGetMachinePlay(game, auxGameData);
    }, 20);
  };

  let startCallback = function(gameState) {
    const game = gameState.game;
    const auxGameData = gameState.auxGameData;
    setTimeout(function() {
      console.log("start callback");
      unsubscribe(startCallback);
      subscribe(moveCallback);
      movingPiece = game.tray.pieces[0];
      let move = mkPiecePoint(movingPiece, moveDest);
      gameEventHandler.move(game, auxGameData, move);
    }, 20);
  };

  // gameDispatcher.register(handler.dispatchHandler);
  subscribe(startCallback);
  gameEventHandler.start(gameParams);
});


/*
let gameService = new GameService(gameParams);

const {gameEventHandler, subscribe, unsubscribe} = mkGameHandler(gameService);

const gameObserver = function(gameState) {
  console.log(`gameObserver - auxGameData: ${stringify(gameState.auxGameData)}`);
  renderGame(gameState);
};

subscribe(gameObserver);

 */
