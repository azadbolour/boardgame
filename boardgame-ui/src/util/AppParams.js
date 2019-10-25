/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module AppParams.
 */

// TODO. Move to MiscUtil.

function getEnv(varName, defaultValue) {
  let value = process.env[varName];
  return value ? value : defaultValue;
};

class AppParams {
  constructor(envType, userName, password, inputDevice) {
    this.envType = envType;
    this.userName = userName;
    this.password = password;
    this.inputDevice = inputDevice;
  }

  // Environment variable names.

  static ENV_ENV_TYPE = 'ENV_TYPE';
  static ENV_USER_NAME = 'USER_NAME';
  static ENV_PASSWORD = 'PASSWORD';
  static ENV_PREFERRED_INPUT_DEVICE = 'PREFERRED_INPUT_DEVICE';

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

  static validatePreferredInputDevice(inputDevice) {
    let valid = AppParams.INPUT_DEVICES.includes(inputDevice);
    if (!valid)
      return {
        valid: false,
        message: `invalid preferred input device ${inputDevice} - valid values are ${stringify(this.INPUT_DEVICES)}`
      };
    return AppParams.validated;
  }

  static defaultParams() {
    let get = getEnv;
    return new AppParams(
      get(AppParams.ENV_ENV_TYPE, AppParams.DEFAULT_ENV_TYPE),
      get(AppParams.ENV_USER_NAME, AppParams.DEFAULT_USER_NAME),
      get(AppParams.ENV_PASSWORD, AppParams.DEFAULT_PASSWORD),
      get(AppParams.ENV_PREFERRED_INPUT_DEVICE, AppParams.DEFAULT_INPUT_DEVICE)
    );
  };


}

export default AppParams;