/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";

export const coinToss = (x, y) => Math.random() < 0.5 ? x : y;

export const checkArray = function(array, message) {
  if (!Array.isArray(array))
    throw {
      name: "not an array",
      message: `${message}: object: ${stringify(array)}`
    };
};

export const checkArrayIndex = function(index, size, message) {
  if (index >= size || index < 0)
    throw {
      name: "index out of bounds",
      message: `${message} - index: ${index}, size: ${size}`
    };
};

export const checkCapacityOverflow = function(size, capacity, message) {
  if (size > capacity)
    throw {
      name: "capacity overflow",
      message: `${message} - required size: ${size}, capacity: ${capacity}`
    };
};

export const zipWith = function(arr1, arr2, zipper) {
  checkArray(arr1, "cannot zip non-array");
  checkArray(arr2, "cannot zip non-array");

  let len = Math.min(arr1.length, arr2.length);

  let zipped = [];
  for (let i = 0; i < len; i++)
    zipped.push(zipper(arr1[i], arr2[i]));

  return zipped;
};

export const range = function(n) {
  return Array.from({length: n}, (v, i) => i);
};

export const convertResponse = function(response, data) {
  let newResponse = Object.create(response);
  newResponse.json = data;
  return newResponse;
};

export const mkErrorState = function() {
  let _error = false;
  let _status = "";
  return {
    get error() { return _error; },
    get status() { return _status; },
    addError: function (message) {
      _status += _error ? "\n" : "";
      _error = true;
      _status += message;
    },
    addErrorState: function(errorState) {
      if (errorState.error) {
        this.addError(errorState.status)
      }
    }
  }
};

export const toCamelCase = function(name) {
  let camelName = name.replace(/(-)([a-z])/g, function(match, dash, initial, offset, string) { return initial.toUpperCase()});
  return camelName;
};

export const getOrElse = function(object, field, defaultValue) {
  const value = object[field];
  return (value !== undefined) ? value : defaultValue;
};

export const orElse = function(value, defaultValue) {
  return (value !== undefined) ? value : defaultValue;
};








