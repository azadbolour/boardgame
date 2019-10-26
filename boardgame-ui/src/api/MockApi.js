/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module MockApi
 */

/*
 * Note. The data structures in this module all work on json objects,
 * and not on UI domain objects. The json objects are those that go
 * on the wire, or objects supporting those that go on the wire.
 */
import MockApiImpl from './MockApiImpl';
// import {stringify} from "../util/Logger";

const promise = function(json) {
  return new Promise(function(resolve, reject) {
    resolve({
      json: json,
      ok: true,
      status: 200,
      statusText: "OK"
    });
  });
};

class MockApi {
  constructor(serverApiUrl, userName, password) {
    // Associative array of game id => game service object.
    this.impls = {};
    this.nextGameId = 0;
  }

  getImpl(gameId) {
    let s = this.impls[gameId];
    if (s === undefined)
      throw `gameId: ${gameId} does not exists`;
    return s;
  }

  // Begin API.

  handShake() {
    let json = {
      serverType: "Mock",
      apiVersion: "1.0"
    };
    return promise(json);
  }

  startGame(gameParams, initPieces, pointValues) {
    this.nextGameId += 1;
    let gameId = this.nextGameId;
    let impl = new MockApiImpl(gameId, gameParams, initPieces, pointValues);
    this.impls[gameId] = impl;
    let gameDto = impl.gameDto;
    return promise(gameDto);
  }

  selectFirstPlayer(gameId) {
    let impl = this.getImpl(gameId);
    return promise(impl.selectFirstPlayer());
  }

  swap(gameId, piece) {
    let impl = this.getImpl(gameId);
    return promise(impl.swap(piece));
  }

  commitPlay(gameId, playPieces) {
    let impl = this.getImpl(gameId);
    return promise(impl.commitPlay(playPieces));
  }

  getMachinePlay(gameId) {
    // console.log(`in getMachinePlay`);
    let impl = this.getImpl(gameId);
    return promise(impl.getMachinePlay());
  }

  closeGame(gameId) {
    return promise({});
  }

  /**
   * Used in tests.
   */
  filledPositions(gameId) {
    let impl = this.getImpl(gameId);
    return promise({
      positions: impl.filledPositions()
    });
  }

  /**
   * Used in tests.
   */
  getMachineTray(gameId) { // For testing.
    let impl = this.getImpl(gameId);
    return promise({
      tray: impl.machineTray
    });
  }

  // End API.

  // Auxiliary functions - TODO. should be generic in a super-class.
  // TODO. Remove from MockGameService.

  posFilled(gameId, pos) {
    let impl = this.getImpl(gameId);
    return promise(impl.posFilled(pos));
  }

  posEmpty(gameId, pos) {
    let impl = this.getImpl(gameId);
    return promise(impl.posEmpty(pos));
  }
}

export default MockApi;



