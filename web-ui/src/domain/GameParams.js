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
import {stringify} from "../util/Logger";

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
  constructor(appParams, dimension, squarePixels, trayCapacity, apiType, gameServerUrl, pieceProviderType, startingPlayer = GameParams.PlayerType.userPlayer) {
    this.appParams = appParams;
    this.dimension = dimension;
    this.squarePixels = squarePixels;
    this.trayCapacity = trayCapacity;
    this.apiType = apiType;
    this.gameServerUrl = gameServerUrl;
    this.pieceProviderType = pieceProviderType;
    this.startingPlayer = startingPlayer; // PlayerType
  }

  static PieceGeneratorType = {
    random: "Random",
    cyclic: "Cyclic"
  };

  static PlayerType = {
    userPlayer: 'user',
    machinePlayer: 'machine'
  };

  static PLAYER_TYPES = [GameParams.PlayerType.userPlayer, GameParams.PlayerType.machinePlayer];

  // Environment variable names.

  static ENV_API_TYPE = 'API_TYPE';
  static ENV_GAME_SERVER_URL = 'GAME_SERVER_URL';

  static DEFAULT_DIMENSION = 5;
  static DEFAULT_SQUARE_PIXELS = 36;
  static DEFAULT_TRAY_SIZE = 5;
  static MOCK_API_TYPE = 'mock';
  static CLIENT_API_TYPE = 'client';
  static API_TYPES = [GameParams.MOCK_API_TYPE, GameParams.CLIENT_API_TYPE];
  static DEFAULT_API_TYPE = GameParams.MOCK_API_TYPE;
  static DEFAULT_GAME_SERVER_URL = 'http://localhost:6587';
  static DEFAULT_PIECE_GENERATOR_TYPE = GameParams.PieceGeneratorType.cyclic;

  static MIN_DIMENSION = 5;
  static MAX_DIMENSION = 25;

  static MIN_SQUARE_PIXELS = 25;
  static MAX_SQUARE_PIXELS = 60;

  static MIN_TRAY_CAPACITY = 3;
  static MAX_TRAY_CAPACITY = 15;

  static validated = {valid: true};

  static validateDimension(dim) {
    let inBounds = dim >= GameParams.MIN_DIMENSION && dim <= GameParams.MAX_DIMENSION;
    if (!inBounds)
      return {
        valid: false,
        message: `invalid dimension ${dim} - valid range is [${GameParams.MIN_DIMENSION}, ${GameParams.MAX_DIMENSION}]`
      };
    let isOdd = (dim % 2) === 1;
    if (!isOdd)
      return {
        valid: false,
        message: `invalid dimension ${dim} - dimension must be odd`
      };
    return GameParams.validated;
  }

  static validateSquarePixels(pix) {
    let inBounds = pix >= GameParams.MIN_SQUARE_PIXELS && pix <= GameParams.MAX_SQUARE_PIXELS;
    if (!inBounds)
      return {
        valid: false,
        message: `invalid square-pixels ${pix} - valid range is [${GameParams.MIN_SQUARE_PIXELS}, ${GameParams.MAX_SQUARE_PIXELS}]`
      };
    return GameParams.validated;
  }

  static validateTrayCapacity(capacity) {
    let inBounds = capacity >= GameParams.MIN_TRAY_CAPACITY && capacity <= GameParams.MAX_TRAY_CAPACITY;
    if (!inBounds)
      return {
        valid: false,
        message: `invalid tray-capacity ${capacity} - valid range is [${GameParams.MIN_TRAY_CAPACITY}, ${GameParams.MAX_TRAY_CAPACITY}]`
      };
    return GameParams.validated;
  }

  static validateApiType(apiType) {
    let valid = GameParams.API_TYPES.includes(apiType);
    if (!valid)
      return {
        valid: false,
        message: `invalid api-type ${apiType} - valid values are ${stringify(GameParams.API_TYPES)}`
      };
    return GameParams.validated;
  }

  static validateStartingPlayer(startingPlayer) {
    let valid = GameParams.PLAYER_TYPES.includes(startingPlayer);
    if (!valid)
      return {
        valid: false,
        message: `invalid starting player ${startingPlayer} - valid values are ${stringify(GameParams.PLAYER_TYPES)}`
      };
    return GameParams.validated;
  }

  static validateGameServerUrl(url) {
    // Note. isWebUri returns the uri if valid, undefined if not.
    let valid = validUrl.isWebUri(url) !== undefined;
    if (!valid)
      return {
        valid: false,
        message: `invalid url ${url}`

      };
    return GameParams.validated;
  }

  static defaultParams() {
    let get = getEnv;
    return new GameParams(
      AppParams.defaultParams(),
      GameParams.DEFAULT_DIMENSION,
      GameParams.DEFAULT_SQUARE_PIXELS,
      GameParams.DEFAULT_TRAY_SIZE,
      get(GameParams.ENV_API_TYPE, GameParams.DEFAULT_API_TYPE),
      get(GameParams.ENV_GAME_SERVER_URL, GameParams.DEFAULT_GAME_SERVER_URL),
      GameParams.DEFAULT_PIECE_GENERATOR_TYPE
    );
  };

  static defaultClientParams() {
    let clientParams = GameParams.defaultParams();
    clientParams.appParams.envType = 'prod'; // TODO. Constant.
    clientParams.apiType = GameParams.CLIENT_API_TYPE;
    clientParams.dimension = 15;
    clientParams.trayCapacity = 7;
    clientParams.pieceProviderType = GameParams.PieceGeneratorType.random;
    return clientParams;
  }

  static defaultClientParamsSmall() {
    let clientParams = GameParams.defaultClientParams();
    clientParams.dimension = 5;
    clientParams.trayCapacity = 3;
    return clientParams;
  }
}

export default GameParams;
