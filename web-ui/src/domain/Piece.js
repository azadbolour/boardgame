/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

const frequencies = {
  'A': 81,
  'B': 15,
  'C': 28,
  'D': 42,
  'E': 127,
  'F': 22,
  'G': 20,
  'H': 61,
  'I': 70,
  'J': 2,
  'K': 8,
  'L': 40,
  'M': 24,
  'N': 67,
  'O': 80,
  'P': 19,
  'Q': 1,
  'R': 60,
  'S': 63,
  'T': 91,
  'U': 28,
  'V': 10,
  'W': 23,
  'X': 2,
  'Y': 20,
  'Z': 1
};

// TODO. blank: 0.
export const worths = {
  'A': 1,
  'B': 1,
  'C': 1,
  'D': 1,
  'E': 1,
  'F': 1,
  'G': 1,
  'H': 1,
  'I': 1,
  'J': 1,
  'K': 1,
  'L': 1,
  'M': 1,
  'N': 1,
  'O': 1,
  'P': 1,
  'Q': 1,
  'R': 1,
  'S': 1,
  'T': 1,
  'U': 1,
  'V': 1,
  'W': 1,
  'X': 1,
  'Y': 1,
  'Z': 1
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
  const distribution = buildLetterDistribution(); // TODO. Factor out.
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

/* Representation of a disabled/inactive/dead location. */
export const DEAD_CHAR = '-';
export const DEAD_PIECE_ID = "-2";
export const DEAD_PIECE = mkPiece(DEAD_CHAR, DEAD_PIECE_ID);

export const isDead = function(ch) { return ch === DEAD_CHAR };
export const isAlive = function(ch) { return !isDead(ch) };

export const pieceIsDead = function(piece) { return isDead(piece.value) }

