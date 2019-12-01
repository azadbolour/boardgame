/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/* Import of react is needed even though it is not used directly in this file!
   Without it the board is not displayed! Why? */
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';
import {queryParams} from './util/UrlUtil';

import GameParams from './domain/GameParams';
import GameService from "./service/GameService"
import {mkGameHandler} from './event/GameHandler';
import {mkEmptyGame} from './domain/Game';
import {emptyAuxGameData, mkAuxGameData} from './domain/AuxGameData';
import {stringify, stringifyNoBracesForEmpty} from "./util/Logger";
import {mkGameState} from "./event/GameState";
import {GameActionTypes} from "./event/GameActionTypes";
// import Amplify, {Auth} from "aws-amplify";
// import {configuration} from "./aws-exports";
// import AppParams from './util/AppParams';
// import {getAuthConfiguration} from './AuthParams';

const urlQueryParams = queryParams(window.location);

const {extracted: gameParams, errorState} = GameParams.fromQueryParams(urlQueryParams);
if (errorState.error)
  console.log(`errors: ${stringify(errorState.status)}`);
console.log(`game params: ${stringify(gameParams)}`);

// /*
//  * Configure Cognito. Static configuration depends on env.
//  * Simplest to do it here.
//  */
// const envType = gameParams.appParams[AppParams.ENV_TYPE_PARAM];
// const configuration = getAuthConfiguration(envType);
// Amplify.configure(configuration);
// const auth = configuration.auth;
// Auth.configure({ auth });

const UNKNOWN_SERVER_TYPE = "unknown";
let serverType = UNKNOWN_SERVER_TYPE;

const rootEl = document.getElementById('root');

let gameService = new GameService(gameParams);

const {gameEventHandler, subscribe, unsubscribe} = mkGameHandler(gameService);

const gameObserver = function(gameState) {
  renderApp(gameState);
};

const renderApp = function(gameState) {
  let gameSpec = <App
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
  let gameState = mkGameState(emptyGame, auxGameData, status, GameActionTypes.START_INIT);

  renderApp(gameState);
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


