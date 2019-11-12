/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/* Import of react is needed even though it is not used directly in this file!
   Without it the board is not displayed! Why? */
import React from 'react';
import ReactDOM from 'react-dom';
import GameComponent from './component/GameComponent';
import {queryParams} from './util/UrlUtil';

import GameParams from './domain/GameParams';
import GameService from "./service/GameService"
// import {mkGameEventHandler} from './event/GameEventHandler';
import {mkGameHandler} from './event/GameHandler';
import {gameDispatcher} from './event/GameDispatcher';
import {mkEmptyGame} from './domain/Game';
import {emptyAuxGameData, mkAuxGameData} from './domain/AuxGameData';
import {stringify, stringifyNoBracesForEmpty} from "./util/Logger";
import {mkGameState} from "./event/GameState";
import {NewActionTypes} from "./event/NewActionTypes";

let urlQueryParams = queryParams(window.location);

const {extracted: gameParams, errorState} = GameParams.fromQueryParams(urlQueryParams);
if (errorState.error)
  console.log(`errors: ${stringify(errorState.status)}`);
console.log(`game params: ${stringify(gameParams)}`);

const rootEl = document.getElementById('root');

const UNKNOWN_SERVER_TYPE = "unknown";
let serverType = UNKNOWN_SERVER_TYPE;

let gameService = new GameService(gameParams);

const {gameEventHandler, subscribe, unsubscribe} = mkGameHandler(gameService);

const gameObserver = function(gameState) {
  console.log(`gameObserver - auxGameData: ${stringify(gameState.auxGameData)}`);
  renderGame(gameState);
};

const renderGame = function(gameState) {
  let gameSpec = <GameComponent
    gameState={gameState}
    gameEventHandler={gameEventHandler}
    serverType={serverType}
  />;

  ReactDOM.render(
    gameSpec,
    rootEl
  );
};


const renderEmptyGameAndStatus = function(status) {
  let emptyGame = mkEmptyGame(gameParams);
  let auxGameData = mkAuxGameData([]);
  // TODO. Better action type.
  let gameState = mkGameState(emptyGame, auxGameData, status, NewActionTypes.START_INIT);

  renderGame(gameState);
};

subscribe(gameObserver);

// TODO. Can this be done generically as a result of dispatching an initial gameState.
const doHandShake = function(service) {
  service.handShake().then(response => {
    if (response.ok) {
      serverType = response.json.serverType;
      renderEmptyGameAndStatus("OK");
    }
    else {
      serverType = UNKNOWN_SERVER_TYPE;
      renderEmptyGameAndStatus(stringifyNoBracesForEmpty(response.json));
    }
  }).catch(reason => {
      serverType = UNKNOWN_SERVER_TYPE;
      renderEmptyGameAndStatus(stringifyNoBracesForEmpty(reason));
    }
  )
};

if (errorState.error)
  renderEmptyGameAndStatus(errorState.status);
else
  doHandShake(gameService);


//--------------------------------------------------

// Future.
// TODO. Add language-code to the query parameters and GameParams - default is en.
// TODO. If not specified get the user's preferred language like this:

// `/** @const */ DEFAULT_VALUE = 'en';
// /** @const */ PREFERRED_LANGUAGE = navigator.language
//   || navigator.userLanguage
//   || navigator.browserLanguage
//   || navigator.systemLanguage
//   || DEFAULT_VALUE;

// Note that in Javascript the language and country codes are dash-separated: 'en-US'.
// On many server languages including Haskell they are underscore-separated: 'en_US. Need to convert.
// But initially we'll just support generic language codes like "en"
// TODO. Transmit the language code to the server - see Converters.


