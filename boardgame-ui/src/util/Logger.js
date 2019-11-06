/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module Logger
 */

// TODO. Add logging for all major function.

import AppParams from './AppParams';

// See AppParams for env types - dev, test, prod.

export const stringify = function(value) {
  return `${JSON.stringify(value)}`;
};

export const stringifyNoBracesForEmpty = function(status) {
  // TODO. Ugly hack for empty object. Clean up. Simple tests did not work!
  let s = stringify(status);
  return (s === "{}") ? "" : s;
};


const logger = {
  init: function(env) {
    this.env = env;
  },

  info: function(message) {
    console.info(message);
  },

  warn: function(message) {
    console.warn(message);
  },

  error: function(message) {
    console.error(message);
  },

  debug: function(message) {
    switch(this.env) {
      case AppParams.DEV_ENV_TYPE:
        console.debug(message);
        break;
      default:
        break;
    }

  },

  logValues() {
    let message = "";
    for (let i = 0; i < arguments.length; i++) {
      let arg = arguments[i];
      if (!Array.isArray(arg))
        message += stringify(arg);
      else if (arg.length === 0 || typeof(arg[0]) !== "object")
        message += stringify(arg);
      else { // array of objects
        // arg.forEach(el => {message += stringify(el)});
        message = arg.map(stringify).join(' ')
      }
    }
    console.log(message);
  }
};

export default logger;

