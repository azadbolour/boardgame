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
import AppParams from './util/AppParams';
import GameService from "./service/GameService"
import {mkGameEventHandler} from './event/GameEventHandler';
import {gameDispatcher} from './event/GameDispatcher';
import {mkEmptyGame} from './domain/Game';
import {emptyAuxGameData} from './domain/AuxGameData';

let params = queryParams(window.location);

// TODO. Login to the game server: need user name and password fields.

let gameParams = GameParams.defaultClientParams();

let settableParameters = {
  'api-type': 'string',
  'env-type': 'string',
  'game-server-url': 'string',
  'dimension': 'int',
  'tray-capacity': 'int',
  'square-pixels': 'int',
  'preferred-input-device': 'string',
  'starting-player': 'string'
};

const initialState = (function() {
  let _error = false;
  let _status = "";
  return {
    get error() { return _error; },
    get status() { return _status; },
    addError: function (message) {
      _status += _error ? "\n" : "";
      _error = true;
      _status += message;
    }
  }
})();

// TODO. Move validation to GameParams once it is refactored to use the module pattern,
// with immutable fields.

// TODO. Game-related constants should be defined in GameParams.
// TODO. General application constants should be defined in AppParams.

const validateParam = function(name, value) {
  switch (name) {
    case 'env-type':
      return AppParams.validateEnvType(value);
    case 'preferred-input-device':
      return AppParams.validatePreferredInputDevice(value);
    case 'api-type': // TODO. Constants. Go into GameParams.
      return GameParams.validateApiType(value);
    case 'game-server-url':
      return GameParams.validateGameServerUrl(value);
    case 'dimension':
      return GameParams.validateDimension(value);
    case 'tray-capacity':
      return GameParams.validateTrayCapacity(value);
    case 'square-pixels':
      return GameParams.validateSquarePixels(value);
    case 'starting-player':
      return GameParams.validateStartingPlayer(value);
    default:
      break;
  }
};

let toCamelCase = function(name) {
  let camelName = name.replace(/(-)([a-z])/g, function(match, dash, initial, offset, string) { return initial.toUpperCase()});
  return camelName;
};

console.log(`game params: ${JSON.stringify(gameParams)}`);

// TODO. Move integer parsing to a util module - must make it more robust.
// TODO. User errors should be reported on the user's UI.
// For now just ignoring with a log message.


for (let name in settableParameters) {
  let value = params.getParam(name);
  if (value === undefined)
    continue;
  if (settableParameters[name] === 'int') {
    value = (/[0-9]+/).test ? Number(value) : NaN;
    if (isNaN(value)) {
      let message = `invalid value ${value} for numeric parameter ${name}`;
      initialState.addError(message);
      console.log(message);
      continue;
    }
  }
  let {valid, message} = validateParam(name, value);
  if (!valid) {
    initialState.addError(message);
    console.log(message);
    continue;
  }
  let property = toCamelCase(name);
  // TODO. Do generically by having a list of app params - imported from AppParams.
  if (name === 'env-type' || name === 'preferred-input-device')
    gameParams.appParams[property] = value;
  else
    gameParams[property] = value;
  console.log(`query param: ${name} = ${value}`);
}

// Special parameter processing.

// No starting player? Randomly choose one.

// let startingPlayer = params.getParam('starting-player');

// if (startingPlayer === undefined) {
//   let playerType = GameParams.PlayerType;
//   startingPlayer = Math.random() < 0.5 ? playerType.userPlayer : playerType.machinePlayer;
//   gameParams.startingPlayer = startingPlayer;
// }

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

// In production the same server serves the UI content and the server API.
// TODO. It should be an error to try to set game server url in production mode.
// It should not be allowed on the user preference page.
// For now it is just ignored.
let origin = window.location.origin;
if (gameParams.appParams.envType === 'prod')
  gameParams.gameServerUrl = origin;

const rootEl = document.getElementById('root');

const UNKNOWN_SERVER_TYPE = "unknown";
let serverType = UNKNOWN_SERVER_TYPE;

const renderGame = function(game, status, auxGameData, changeStage) {
  let gameSpec = <GameComponent game={game} status={status} auxGameData={auxGameData} serverType={serverType}/>;
  ReactDOM.render(
    gameSpec,
    rootEl
  );
};

const gameChangeObserver = function(changeStage, game, status, auxGameData) {
  renderGame(game, status, auxGameData, changeStage);
};

let gameService = new GameService(gameParams);
let gameEventHandler = mkGameEventHandler(gameService);
gameDispatcher.register(gameEventHandler.dispatchHandler);

gameEventHandler.registerChangeObserver(gameChangeObserver);

console.log(`game params: ${JSON.stringify(gameParams)}`);

const doHandShake = function(service, handler) {
  service.handShake().then(response => {
    if (response.ok) {
      serverType = response.json.serverType;
      handler("OK");
    }
    else {
      serverType = UNKNOWN_SERVER_TYPE;
      handler(JSON.stringify(response.json));
    }
  }).catch(reason => {
      serverType = UNKNOWN_SERVER_TYPE;
      handler(reason);
    }
  )
};

const renderEmptyGame = function(status) {
  let emptyGame = mkEmptyGame(gameParams);
  renderGame(emptyGame, status, emptyAuxGameData());
};

if (initialState.error)
  renderEmptyGame(initialState.status);
else
  doHandShake(gameService, renderEmptyGame);





