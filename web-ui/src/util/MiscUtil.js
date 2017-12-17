/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";

// export const miscUtil = {
//   sleep: function(millis) {
//     function nowMillis() {
//       let now = new Date();
//       return now.getTime();
//     };
//     let toMillis = nowMillis() + millis;
//     while (nowMillis() < toMillis);
//   }
//
// };

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







