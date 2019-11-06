/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module AppParams.
 */

import {stringify} from "./Logger";
import GameParams from "../domain/GameParams";
import {queryParamsToObject} from "./UrlUtil";
import {orElse} from "./MiscUtil";
import {gameConf} from "../Conf";
const validUrl = require('valid-url');

// TODO. Move to MiscUtil.

function getEnv(varName, defaultValue) {
  let value = process.env[varName];
  return value ? value : defaultValue;
}

// TODO. User name and password not provided in the URL. Obtained by identity service. Remove from here.

class AppParams {
  constructor(envType, apiType, serverUrl, inputDevice) {
    this.envType = envType;
    this.apiType = apiType;
    this.serverUrl = serverUrl;
    this.inputDevice = inputDevice;
  }

  // Names of parameters settable in the URL for testing.

  static ENV_TYPE_PARAM = 'env-type';
  static API_TYPE_PARAM = 'api-type';
  static SERVER_URL_PARAM = 'server-url';
  static INPUT_DEVICE_PARAM = 'input-device';

  static MOCK_API_TYPE = 'mock';
  static CLIENT_API_TYPE = 'client';
  static API_TYPES = [GameParams.MOCK_API_TYPE, GameParams.CLIENT_API_TYPE];
  static DEFAULT_API_TYPE = GameParams.MOCK_API_TYPE;
  static DEFAULT_SERVER_URL = 'http://localhost:6587';

  static DEV_ENV_TYPE = 'dev';
  static TEST_ENV_TYPE = 'test';
  static PROD_ENV_TYPE = 'prod';
  static ENV_TYPES = [AppParams.DEV_ENV_TYPE, AppParams.TEST_ENV_TYPE, AppParams.PROD_ENV_TYPE];
  static DEFAULT_ENV_TYPE = AppParams.DEV_ENV_TYPE;
  static DEFAULT_USER_NAME = 'You';
  static DEFAULT_PASSWORD = 'admin';

  static MOUSE_INPUT = 'mouse';
  static TOUCH_INPUT = 'touch';

  static DEFAULT_INPUT_DEVICE = AppParams.MOUSE_INPUT;

  static INPUT_DEVICES = [AppParams.MOUSE_INPUT, AppParams.TOUCH_INPUT];

  static validated = {valid: true};

  static validateEnvType(envType) {
    let valid = AppParams.ENV_TYPES.includes(envType);
    if (!valid)
      return {
        valid: false,
        message: `invalid env-type ${envType} - valid values are ${stringify(AppParams.ENV_TYPES)}`
      };
    return AppParams.validated;
  }

  static validateApiType(apiType) {
    let valid = AppParams.API_TYPES.includes(apiType);
    if (!valid)
      return {
        valid: false,
        message: `invalid api-type ${apiType} - valid values are ${stringify(GameParams.API_TYPES)}`
      };
    return GameParams.validated;
  }

  static validateServerUrl(url) {
    // Note. isWebUri returns the uri if valid, undefined if not.
    let valid = validUrl.isWebUri(url) !== undefined;
    if (!valid)
      return {
        valid: false,
        message: `invalid url ${url}`

      };
    return GameParams.validated;
  }

  static validatePreferredInputDevice(inputDevice) {
    let valid = AppParams.INPUT_DEVICES.includes(inputDevice);
    if (!valid)
      return {
        valid: false,
        message: `invalid preferred input device ${inputDevice} - valid values are ${stringify(this.INPUT_DEVICES)}`
      };
    return AppParams.validated;
  }

  static mkDefaultParams() {
    return new AppParams(
      orElse(gameConf.appParams[AppParams.ENV_TYPE_PARAM], AppParams.DEFAULT_ENV_TYPE),
      orElse(gameConf.appParams[AppParams.API_TYPE_PARAM], AppParams.DEFAULT_API_TYPE),
      orElse(gameConf.appParams[AppParams.SERVER_URL_PARAM], AppParams.DEFAULT_SERVER_URL),
      orElse(gameConf.appParams[AppParams.INPUT_DEVICE_PARAM], AppParams.DEFAULT_INPUT_DEVICE)
    )
  }

  static validateParam = function(name, value) {
    switch (name) {
      case AppParams.ENV_TYPE_PARAM:
        return AppParams.validateEnvType(value);
      case AppParams.API_TYPE_PARAM:
        return GameParams.validateApiType(value);
     case AppParams.INPUT_DEVICE_PARAM:
        return AppParams.validatePreferredInputDevice(value);
      default:
        break;
    }
  };

  // TODO. Add preferred-input-device. But testing it is a challenge.
  // TODO. These should only be settable in dev and test environments.
  // Note. Do not add server-url. It should not be settable by user in production. Set in config file.
  static settableParameters = (function() {
    let settables = {};
    settables[AppParams.ENV_TYPE_PARAM] = 'string'; // TODO. Constant.
    settables[AppParams.API_TYPE_PARAM] = 'string';
    settables[AppParams.INPUT_DEVICE_PARAM] = 'string';
    return settables;
  })();

  static fromQueryParams = function(queryParams) {
    return queryParamsToObject(queryParams,
      AppParams.settableParameters, AppParams.validateParam, AppParams.mkDefaultParams);
  }
}

export default AppParams;