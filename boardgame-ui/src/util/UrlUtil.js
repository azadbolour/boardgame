/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module UrlUtil */

export const queryParams = function(location) {
  /**
   * Get query parameters from the url.
   * @param location - The url is called location in javascript.
   * @returns A javascript object with query parameter names as field names,
   * and an array of the corresponding query parameter values as a field's value.
   */
  let getQueryParams = function(location) {
    let queryParams = {};
    location.search.substr(1).split('&').forEach(function(item) {
      let keyValue = item.split('='),
        key = keyValue[0],
        value = keyValue[1] && decodeURIComponent(keyValue[1]);
      (key in queryParams) ? queryParams[key].push(value) : queryParams[key] = [value]
    });
    return queryParams;
  };

  let _params = getQueryParams(location);

  return {
    /**
     * Get the first or the only value of a query parameter.
     * @param name The name of the query parameter.
     * @returns The value or 'undefined' if there is no query parameter with the given name.
     */
    getParam: function(name) {
      return (name in _params) ? _params[name][0] : undefined;
    }
  };
};


