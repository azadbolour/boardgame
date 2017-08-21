/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

'use strict';

import GameParams from "../domain/GameParams";
import {mkPiece} from "../domain/Piece";
import GameService from "../service/GameService";
import TestUtil from "../__tests__/TestHelper";
import {stringify} from "../util/Logger";

// TODO. URGENT. Fail on rejection.
// TODO. Better use game event handler rather than game service - better error handling.

test('start game and make user and machine plays', () => {
  let gameParams = GameParams.defaultClientParams();
  let game = undefined;
  let leftPiece = mkPiece('B', 'idLeft');
  let rightPiece = mkPiece('T', 'idRight');
  let initUserTray = [leftPiece, rightPiece];

  let gameService = new GameService(gameParams);
  gameService.start([], initUserTray, []).
  then(response => {
    game = response.json;
    console.log(`${stringify(game)}`);
    expect(game.tray.pieces.length).toBe(gameParams.trayCapacity);
    expect(game.board.dimension).toBe(gameParams.dimension);
    game = TestUtil.addInitialPlayToGame(game);
    let playPieces = game.getCompletedPlayPieces();
    console.log(`playPieces: ${stringify(playPieces)}`);
    return gameService.commitUserPlay(game.gameId, playPieces);
  }).
  then(response => {
    let refillPieces = response.json;
    expect(refillPieces.length).toBe(2);
    return gameService.getMachinePlay(game.gameId);
    // TODO. Add replacement pieces to the tray.
    // game.clearPlay(); // TODO. Move this before return.
  })
});









