/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module GameParams.
 */

import AppParams from '../util/AppParams';
import {stringify} from "../util/Logger";
import {gameConf} from "../Conf";
import {coinToss, orElse, toCamelCase} from "../util/MiscUtil";
import {queryParamsToObject} from "../util/UrlUtil";

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
  constructor(appParams, dimension, squarePixels, trayCapacity, pieceProviderType, startingPlayer) {
    this.appParams = appParams;
    this.dimension = dimension;
    this.squarePixels = squarePixels;
    this.trayCapacity = trayCapacity;
    this.pieceProviderType = pieceProviderType;
    this.startingPlayer = startingPlayer; // PlayerType
  }

  static randomStartingPlayer() {
    const {userPlayer, machinePlayer} = GameParams.PlayerType;
    return coinToss(userPlayer, machinePlayer);
  }

  static PieceGeneratorType = {
    random: "Random",
    cyclic: "Cyclic"
  };

  static PlayerType = {
    userPlayer: 'user',
    machinePlayer: 'machine'
  };

  static DIMENSION_PARAM = 'dimension';
  static SQUARE_PIXELS_PARAM = 'square-pixels';
  static TRAY_CAPACITY_PARAM = 'tray-capacity';
  static STARTING_PLAYER_PARAM = 'starting-player';

  static DIMENSION_FIELD = toCamelCase(GameParams.DIMENSION_PARAM);
  static SQUARE_PIXELS_FIELD = toCamelCase(GameParams.SQUARE_PIXELS_PARAM);;
  static TRAY_CAPACITY_FIELD = toCamelCase(GameParams.TRAY_CAPACITY_PARAM);;
  static STARTING_PLAYER_FIELD = toCamelCase(GameParams.STARTING_PLAYER_PARAM);;

  static PLAYER_TYPES = [GameParams.PlayerType.userPlayer, GameParams.PlayerType.machinePlayer];

  static DEFAULT_DIMENSION = 5;
  static DEFAULT_SQUARE_PIXELS = 33;
  static DEFAULT_TRAY_SIZE = 5;
  static DEFAULT_PIECE_GENERATOR_TYPE = GameParams.PieceGeneratorType.cyclic;

  static MIN_DIMENSION = 5;
  static MAX_DIMENSION = 25;

  static MIN_SQUARE_PIXELS = 20;
  static MAX_SQUARE_PIXELS = 60;

  static MIN_TRAY_CAPACITY = 3;
  static MAX_TRAY_CAPACITY = 15;

  // TODO. Move to a ValidationUtil. Duplicated in AppParams.
  static validated = AppParams.validated; // {valid: true};

  // TODO. validateAppParams.

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

  static validateStartingPlayer(startingPlayer) {
    let valid = GameParams.PLAYER_TYPES.includes(startingPlayer);
    if (!valid)
      return {
        valid: false,
        message: `invalid starting player ${startingPlayer} - valid values are ${stringify(GameParams.PLAYER_TYPES)}`
      };
    return GameParams.validated;
  }

  static UNDEFINED_STARTING_PLAYER = undefined;

  static mkDefaultParams = function() {
    return new GameParams(
      AppParams.mkDefaultParams(),
      orElse(gameConf[GameParams.DIMENSION_FIELD], GameParams.DEFAULT_DIMENSION),
      orElse(gameConf[GameParams.SQUARE_PIXELS_FIELD], GameParams.DEFAULT_SQUARE_PIXELS),
      orElse(gameConf[GameParams.TRAY_CAPACITY_FIELD], GameParams.DEFAULT_TRAY_SIZE),
      GameParams.DEFAULT_PIECE_GENERATOR_TYPE,
      GameParams.UNDEFINED_STARTING_PLAYER
    )
  };

  static mkDefaultClientParams = function() {
    let clientParams = GameParams.mkDefaultParams();
    clientParams.appParams.envType = 'prod'; // TODO. Constant.
    clientParams.apiType = GameParams.CLIENT_API_TYPE;
    clientParams.dimension = 13;
    clientParams.trayCapacity = 8;
    clientParams.pieceProviderType = GameParams.PieceGeneratorType.random;
    return clientParams;
  };

  static mkDefaultClientParamsSmall = function() {
    let clientParams = GameParams.mkDefaultClientParams();
    clientParams.dimension = 5;
    clientParams.trayCapacity = 3;
    return clientParams;
  };

  static validateParam = function(name, value) {
    switch (name) {
      case GameParams.DIMENSION_PARAM:
        return GameParams.validateDimension(value);
      case GameParams.TRAY_CAPACITY_PARAM:
        return GameParams.validateTrayCapacity(value);
      case GameParams.SQUARE_PIXELS_PARAM:
        return GameParams.validateSquarePixels(value);
      case GameParams.STARTING_PLAYER_PARAM:
        return GameParams.validateStartingPlayer(value);
      default:
        break;
    }
  };

  static settableParameters = (function() {
    let settables = {};
    settables[GameParams.DIMENSION_PARAM] = 'int'; // TODO. Constant.
    settables[GameParams.SQUARE_PIXELS_PARAM] = 'int';
    settables[GameParams.TRAY_CAPACITY_PARAM] = 'int';
    settables[GameParams.STARTING_PLAYER_PARAM] = 'string';
    return settables;
  })();

  static fromQueryParams = function(queryParams) {
    let {extracted: appExtracted, errorState: appErrorState} = AppParams.fromQueryParams(queryParams);
    let {extracted, errorState} = queryParamsToObject(queryParams,
      GameParams.settableParameters, GameParams.validateParam, GameParams.mkDefaultParams);
    errorState.addErrorState(appErrorState);
    extracted.appParams = appExtracted;
    return {extracted, errorState};
  }
}

export default GameParams;
