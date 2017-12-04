/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module ClientApi */

import {StartGameRequestConverter} from "./Converters";
const basic = require('basic-authorization-header');
const fetch = require('node-fetch');

// TODO. Logging for requests and responses.

class ClientApi {
  constructor(gameServerUrl, userName, password) {
    this.gameServerUrl = gameServerUrl;
    this.userName = userName;
    this.password = password;
  }

  startGame(gameParams, initGridPieces, initUserTray, initMachineTray) {
    // let body = JSON.stringify([gameParams, initGridPieces, initUserTray, initMachineTray]);
    let startGameRequest = StartGameRequestConverter.toJson(gameParams, initGridPieces, initUserTray, initMachineTray);
    let body = JSON.stringify(startGameRequest);
    let request = restManager.mkPostRequest(body);
    let promise = restManager.send(request, this.gameServerUrl, '/game/game');
    return promise;
  }

  commitPlay(gameId, playPieces) {
    let body = JSON.stringify(playPieces);
    let request = restManager.mkPostRequest(body);
    let restPath = `/game/commit-play/${gameId}`;
    let promise = restManager.send(request, this.gameServerUrl, restPath);
    return promise;
  }
  
  getMachinePlay(gameId) {
    let init = restManager.mkEmptyPostRequest();
    let restPath = `/game/machine-play/${gameId}`;
    let promise = restManager.send(init, this.gameServerUrl, restPath);
    return promise;
  }

  endPlay(gameId) {
    let init = restManager.mkEmptyPostRequest();
    let restPath = `/game/end-game/${gameId}`;
    let promise = restManager.send(init, this.gameServerUrl, restPath);
    return promise;
  }

  swap(gameId, piece) {
    let body = JSON.stringify(piece);
    let request = restManager.mkPostRequest(body);
    let requestPath = '/game/swap-piece/' + gameId;
    let promise = restManager.send(request, this.gameServerUrl, requestPath);
    return promise;
  }
}

const restManager = {
  send(request, serverUrl, restPath) {
    // console.log(`request: ${JSON.stringify(request.method)}\n${JSON.stringify(restPath)}\n${JSON.stringify(request.body)}`);
    let restUrl = serverUrl + restPath;
    let resp = undefined
    let promise = fetch(restUrl, request)
      .then(function(response) {
        resp = response;
        return response.json(); // This is a promise.
      })
      .then(function(json) {
        // console.log(`response: ${JSON.stringify(json)}`);
        return {
          json: json,
          ok: resp.ok,
          status: resp.status,
          statusText: resp.statusText
        };
      }); // This is a promise.
    return promise;
  },

  headers() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      mode: 'cors' // ,
      // credentials: 'same-origin' // ,
      // 'Authorization': basic(this.userName, this.password) // ,
      // 'Access-Control-Allow-Origin': "http://localhost:3000" // TODO. Just a response type. Security hole. See CORS.
    };
  },

  headersForEmptyBody() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      mode: 'cors',
      'Content-Length': '0' // ,
      // 'Access-Control-Allow-Origin': "http://localhost:3000" // Could not get this to work.
    };
  },

  mkGetRequest() {
    return {
      method: 'GET',
      headers: this.headers()
    };
  },

  mkPostRequest(body) {
    return {
      method: 'POST',
      headers: this.headers(),
      body: body
    };
  },

  mkEmptyPostRequest() {
    return {
      method: 'POST',
      headers: this.headersForEmptyBody()
    };
  }
};

export default ClientApi;
