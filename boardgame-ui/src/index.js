/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/* Import of react is needed even though it is not used directly in this file!
   Without it the board is not displayed! Why? */
import React from 'react';
import ReactDOM from 'react-dom';
import {createStore} from 'redux';
import {Provider} from 'react-redux'
import GameComponent from './component/GameComponent';
import {queryParams} from './util/UrlUtil';
import {mkGameReducer} from "./event/GameReducer";

import GameParams from './domain/GameParams';
import GameService from "./service/GameService"
import {mkGameEventHandler} from './event/GameEventHandler';
import {gameDispatcher} from './event/GameDispatcher';
import {mkEmptyGame} from './domain/Game';
import {emptyAuxGameData} from './domain/AuxGameData';
import {stringify, stringifyNoBracesForEmpty} from "./util/Logger";

let urlQueryParams = queryParams(window.location);

const {extracted: gameParams, errorState} = GameParams.fromQueryParams(urlQueryParams);
if (errorState.error)
  console.log(`errors: ${stringify(errorState.status)}`);
console.log(`game params: ${stringify(gameParams)}`);

const rootEl = document.getElementById('root');

const UNKNOWN_SERVER_TYPE = "unknown";
let serverType = UNKNOWN_SERVER_TYPE;

// TODO. Use App.
const renderGame = function(game, status, auxGameData, changeStage) {
  let gameSpec =
    <Provider store={{store}}>
      <GameComponent game={game} status={status} auxGameData={auxGameData} serverType={serverType}/>
    </Provider>;
  ReactDOM.render(
    gameSpec,
    rootEl
  );
};

const gameChangeObserver = function(changeStage, game, status, auxGameData) {
  renderGame(game, status, auxGameData, changeStage);
};

let gameService = new GameService(gameParams);

const gameReducer = mkGameReducer(gameParams, gameService);
const store = createStore(gameReducer);

let gameEventHandler = mkGameEventHandler(gameService);
gameDispatcher.register(gameEventHandler.dispatchHandler);

gameEventHandler.registerChangeObserver(gameChangeObserver);

const doHandShake = function(service, handler) {
  service.handShake().then(response => {
    if (response.ok) {
      serverType = response.json.serverType;
      handler("OK");
    }
    else {
      serverType = UNKNOWN_SERVER_TYPE;
      handler(stringifyNoBracesForEmpty(response.json));
    }
  }).catch(reason => {
      serverType = UNKNOWN_SERVER_TYPE;
      handler(stringifyNoBracesForEmpty(reason));
    }
  )
};

const renderEmptyGame = function(status) {
  let emptyGame = mkEmptyGame(gameParams);
  renderGame(emptyGame, status, emptyAuxGameData());
};

if (errorState.error)
  renderEmptyGame(errorState.status);
else
  doHandShake(gameService, renderEmptyGame);


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


