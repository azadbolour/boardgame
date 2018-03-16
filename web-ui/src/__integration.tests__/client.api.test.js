/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

'use strict';

import GameParams from "../domain/GameParams";
import {mkPiece} from "../domain/Piece";
import {mkPoint} from "../domain/Point";
import {mkMovePlayPiece, mkCommittedPlayPiece} from "../domain/PlayPiece";
import * as PlayPiece from "../domain/PlayPiece";
import GameService from "../service/GameService";
import TestUtil from "../__tests__/TestHelper";
import {stringify} from "../util/Logger";
import * as PointValue from '../domain/PointValue';

// TODO. URGENT. Fail on rejection.
// TODO. Better use game event handler rather than game service - better error handling.

test('start game and make user and machine plays', () => {
  let gameParams = GameParams.defaultClientParamsSmall();
  // Use deterministic piece generation in tests.
  gameParams.pieceProviderType = GameParams.PieceGeneratorType.cyclic;
  let game = undefined;
  let uPieces = [mkPiece('B', "1"), mkPiece('E', "2"), mkPiece('T', "3")];
  let mPieces = [mkPiece('S', "4"), mkPiece('T', "5"), mkPiece('Z', "6")];
  let center = parseInt(gameParams.dimension/2);

  let gameService = new GameService(gameParams);

  let valueFactory = PointValue.mkValueFactory(gameParams.dimension);
  let pointValues = valueFactory.mkEmptyValueGrid();

  gameService.start([], uPieces, mPieces, pointValues).
  then(response => {
    game = response.json;
    console.log(`${stringify(game)}`);
    expect(game.tray.pieces.length).toBe(gameParams.trayCapacity);
    expect(game.board.dimension).toBe(gameParams.dimension);
    // game = TestUtil.addInitialPlayToGame(game);
    // let playPieces = game.getCompletedPlayPieces();
    // Make a horizontal play of BET.
    let playPieces = [
      mkMovePlayPiece(uPieces[0], mkPoint(center, center - 1)),
      mkMovePlayPiece(uPieces[1], mkPoint(center, center)),
      mkMovePlayPiece(uPieces[2], mkPoint(center, center + 1))
    ];
    console.log(`playPieces: ${stringify(playPieces)}`);
    return gameService.commitUserPlay(game.gameId, playPieces);
  }).
  then(response => {
    let {gameMiniState, replacementPieces} = response.json;
    expect(replacementPieces.length).toBe(3);
    expect(gameMiniState.lastPlayScore).toBeGreaterThan(0);
    return gameService.getMachinePlay(game.gameId);
    // TODO. Add replacement pieces to the tray.
    // game.clearPlay(); // TODO. Move this before return.
  }).then(response => {
    console.log(`machine play response: ${stringify(response.json)}`);
    let {gameMiniState, playedPieces} = response.json;
    console.log(`machine play: ${stringify(playedPieces)}`);
    let moves = PlayPiece.movedGridPieces(playedPieces);
    expect(moves.length).toBeGreaterThan(1);
    expect(gameMiniState.lastPlayScore).toBeGreaterThan(0);
    return gameService.closeGame(game.gameId);
  }).then(response => {
    let unitResponse = response.json;
    console.log(`end json response: ${stringify(unitResponse)}`)
  });
});









