/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

// TODO. blank: 2.
const frequencies = {
  'A': 9,
  'B': 2,
  'C': 2,
  'D': 4,
  'E': 10,
  'F': 2,
  'G': 3,
  'H': 2,
  'I': 9,
  'J': 1,
  'K': 1,
  'L': 4,
  'M': 2,
  'N': 6,
  'O': 8,
  'P': 2,
  'Q': 1,
  'R': 6,
  'S': 4,
  'T': 6,
  'U': 4,
  'V': 2,
  'W': 2,
  'X': 1,
  'Y': 2,
  'Z': 1
};

// TODO. blank: 0.
export const worths = {
  'A': 1,
  'B': 3,
  'C': 3,
  'D': 2,
  'E': 1,
  'F': 4,
  'G': 2,
  'H': 4,
  'I': 1,
  'J': 8,
  'K': 5,
  'L': 1,
  'M': 3,
  'N': 1,
  'O': 1,
  'P': 3,
  'Q': 10,
  'R': 1,
  'S': 1,
  'T': 1,
  'U': 1,
  'V': 4,
  'W': 4,
  'X': 8,
  'Y': 4,
  'Z': 10
};


export const mkPiece = function(value, id) {
  let _value = value;
  let _id = id;

  return {
    get value() { return _value; },
    get id() { return _id; },
    clone: function() {
      return mkPiece(_value, _id);
    }
  };
};

export const eq = function(piece1, piece2) {
  return piece1.value === piece2.value &&
    piece1.id === piece2.id;
};

// TODO. sum = distribution[25].dist.
const buildLetterDistribution = function() {
  let distribution = [];
  const aCode = 'A'.charCodeAt(0);
  let dist = 0;
  for (let i = 0; i < 26; i++) {
    let code = aCode + i;
    let letter = String.fromCharCode(code);
    dist += frequencies[letter];
    distribution.push({
      'letter': letter,
      'dist': dist
    });
  }
  return distribution;
};

/**
 * Get a random letter from a distribution - not from a bag of letters!
 * Successive letters are independent and equally distributed.
 * @returns {string}
 */
export const randomLetter = function() {
  const distribution = buildLetterDistribution();
  const height = distribution[25].dist;
  const d = Math.floor(Math.random() * height);
  for (let i = 0; i < 26; i++)
    if (distribution[i].dist >= d)
      return distribution[i].letter;
};

export const fromJson = function(json) {
  return mkPiece(json.value, json.id);
};

export const NO_PIECE_VALUE = '';
export const NO_PIECE_ID = String(-1);
export const NO_PIECE = mkPiece(NO_PIECE_VALUE, NO_PIECE_ID);

