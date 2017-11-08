/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module GameParams.
 */

const validUrl = require('valid-url');
import AppParams from '../util/AppParams';

// TODO. Need to export API types.
// TODO. env type, api type, user, password need to go to Util package -
// needed there - avoid circular package dependencies AppParams.

// TODO. Move to MiscUtil.
function getEnv(varName, defaultValue) {
  let value = process.env[varName];
  let res = value ? value : defaultValue;
  return res;
}

class GameParams {
  constructor(appParams, dimension, squarePixels, trayCapacity, apiType, gameServerUrl) {
    this.appParams = appParams;
    this.dimension = dimension;
    this.squarePixels = squarePixels;
    this.trayCapacity = trayCapacity;
    this.apiType = apiType;
    this.gameServerUrl = gameServerUrl;
  }

  // Environment variable names.

  static ENV_API_TYPE = 'API_TYPE';
  static ENV_GAME_SERVER_URL = 'GAME_SERVER_URL';

  static DEFAULT_DIMENSION = 5;
  static DEFAULT_SQUARE_PIXELS = 33;
  static DEFAULT_TRAY_SIZE = 5;
  static MOCK_API_TYPE = 'mock';
  static CLIENT_API_TYPE = 'client';
  static API_TYPES = [GameParams.MOCK_API_TYPE, GameParams.CLIENT_API_TYPE];
  static DEFAULT_API_TYPE = GameParams.MOCK_API_TYPE;
  static DEFAULT_GAME_SERVER_URL = 'http://localhost:6587';

  static validateDimension = dim => dim >= 5 && dim <= 15;
  static validateSquarePixels = pix => pix >= 15 && pix <= 60;
  static validateTrayCapacity = cap => cap >= 3 && cap <=10
  static validateApiType = apiType => GameParams.API_TYPES.includes(apiType);
  // Note. isWebUri returns the uri if valid, undefined if not.
  static validateGameServerUrl = url => (validUrl.isWebUri(url) !== undefined);

  static defaultParams() {
    let get = getEnv;
    return new GameParams(
      AppParams.defaultParams(),
      GameParams.DEFAULT_DIMENSION,
      GameParams.DEFAULT_SQUARE_PIXELS,
      GameParams.DEFAULT_TRAY_SIZE,
      get(GameParams.ENV_API_TYPE, GameParams.DEFAULT_API_TYPE),
      get(GameParams.ENV_GAME_SERVER_URL, GameParams.DEFAULT_GAME_SERVER_URL)
    );
  };

  static defaultClientParams() {
    let clientParams = GameParams.defaultParams();
    clientParams.appParams.envType = 'prod'; // TODO. Constant.
    clientParams.apiType = GameParams.CLIENT_API_TYPE;
    clientParams.dimension = 15;
    clientParams.trayCapacity = 7;
    return clientParams;
  }

  static defaultClientParamsSmall() {
    let clientParams = GameParams.defaultParams();
    clientParams.appParams.envType = 'prod'; // TODO. Constant.
    clientParams.apiType = GameParams.CLIENT_API_TYPE;
    clientParams.dimension = 5;
    clientParams.trayCapacity = 3;
    return clientParams;
  }
}

export default GameParams;
