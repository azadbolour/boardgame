/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module AppParams.
 */

import {stringify} from "./Logger";
import {queryParamsToObject} from "./UrlUtil";
import {orElse, toCamelCase} from "./MiscUtil";
import {gameConf} from "../Conf";
const validUrl = require('valid-url');

// TODO. Move to MiscUtil.

function getEnv(varName, defaultValue) {
  let value = process.env[varName];
  return value ? value : defaultValue;
}

// TODO. User name and password not provided in the URL. Obtained by identity service. Remove from here.

class AppParams {
  constructor(envType, apiType, serverUrl, inputDevice, userName) {
    this.envType = envType;
    this.apiType = apiType;
    this.serverUrl = serverUrl;
    this.inputDevice = inputDevice;
    this.userName = userName;
  }

  // Names of parameters settable in the URL for testing.

  static ENV_TYPE_PARAM = 'env-type';
  static API_TYPE_PARAM = 'api-type';
  static SERVER_URL_PARAM = 'server-url';
  static INPUT_DEVICE_PARAM = 'input-device';

  static ENV_TYPE_FIELD = toCamelCase(AppParams.ENV_TYPE_PARAM);
  static API_TYPE_FIELD = toCamelCase(AppParams.API_TYPE_PARAM);
  static SERVER_URL_FIELD = toCamelCase(AppParams.SERVER_URL_PARAM);
  static INPUT_DEVICE_FIELD = toCamelCase(AppParams.INPUT_DEVICE_PARAM);

  static MOCK_API_TYPE = 'mock';
  static CLIENT_API_TYPE = 'client';
  static API_TYPES = [AppParams.MOCK_API_TYPE, AppParams.CLIENT_API_TYPE];
  static DEFAULT_API_TYPE = AppParams.MOCK_API_TYPE;
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

  // TODO. Move to a ValidationUtil.
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
        message: `invalid api-type ${apiType} - valid values are ${stringify(AppParams.API_TYPES)}`
      };
    return AppParams.validated;
  }

  static validateServerUrl(url) {
    // Note. isWebUri returns the uri if valid, undefined if not.
    let valid = validUrl.isWebUri(url) !== undefined;
    if (!valid)
      return {
        valid: false,
        message: `invalid url ${url}`

      };
    return AppParams.validated;
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
      orElse(gameConf.appParams[AppParams.ENV_TYPE_FIELD], AppParams.DEFAULT_ENV_TYPE),
      orElse(gameConf.appParams[AppParams.API_TYPE_FIELD], AppParams.DEFAULT_API_TYPE),
      orElse(gameConf.appParams[AppParams.SERVER_URL_FIELD], AppParams.DEFAULT_SERVER_URL),
      orElse(gameConf.appParams[AppParams.INPUT_DEVICE_FIELD], AppParams.DEFAULT_INPUT_DEVICE),
      AppParams.DEFAULT_USER_NAME
    )
  }

  static validateParam = function(name, value) {
    switch (name) {
      case AppParams.ENV_TYPE_PARAM:
        return AppParams.validateEnvType(value);
      case AppParams.API_TYPE_PARAM:
        return AppParams.validateApiType(value);
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