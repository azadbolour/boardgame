/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


const frequencies = {
  'A': 10,
  'B': 3,
  'C': 3,
  'D': 3,
  'E': 20,
  'F': 3,
  'G': 3,
  'H': 5,
  'I': 8,
  'J': 3,
  'K': 3,
  'L': 4,
  'M': 4,
  'N': 5,
  'O': 10,
  'P': 3,
  'Q': 1,
  'R': 6,
  'S': 15,
  'T': 3,
  'U': 7,
  'V': 3,
  'W': 3,
  'X': 2,
  'Y': 5,
  'Z': 2
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

