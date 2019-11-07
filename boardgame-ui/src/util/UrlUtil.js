/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import {mkErrorState, toCamelCase} from "./MiscUtil";
import {stringify} from "./Logger";

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

  console.log(`in queryParams method: ${stringify(_params)}`);

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

/**
 * Validate and extract a set of query parameters adding them to an object.
 *
 * @param queryParams The query parameter object obtained from the URL.
 * @param paramSpec Include the names and types of the parameters to be extracted.
 * @param validator The parameter validator.
 * @param mkDefaultParams Initializer of the extracted object - fills iin default values.
 *
 * @returns {extracted, errorState} The extracted object and validation errors.
 */
export const queryParamsToObject = function(queryParams, paramSpec, validator, mkDefaultParams) {
  let errorState = mkErrorState();
  let extracted = mkDefaultParams();

  console.log(`in queryParamsToObject: default object: ${stringify(extracted)}`);
  console.log(`paramSpec: ${stringify(paramSpec)}`);
  for (let name in paramSpec) {
    const fieldName = toCamelCase(name);
    console.log(`name: ${name}`);
    if (!paramSpec.hasOwnProperty(name))
      continue;
    console.log(`name: ${name}`);
    let value = queryParams.getParam(name);
    if (value === undefined)
      continue;
    if (paramSpec[name] === 'int') {
      // TODO. Abstract and bullet-proof integer parsing to a util method.
      value = (/[0-9]+/).test ? Number(value) : NaN;
      if (isNaN(value)) {
        let message = `invalid value ${value} for numeric parameter ${name}`;
        errorState.addError(message);
        continue;
      }
    }
    let {valid, message} = validator(name, value);
    if (!valid) {
      errorState.addError(message);
      continue;
    }
    // let property = toCamelCase(name);
    console.log(`${stringify(name)} ... ${stringify(value)}`);
    extracted[fieldName] = value;
  }

  console.log(`returning from queryParamsToObject: extracted: ${stringify(extracted)}, errorState: ${stringify(errorState)}`);

  return {
    extracted,
    errorState
  };

};


