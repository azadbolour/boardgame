
/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import {stringify} from "../util/Logger";
import {mkMultiplierGrid, ScoreMultiplierType, scoreMultiplier} from '../domain/ScoreMultiplier';
import {mkPoint} from '../domain/Point';
import * as Point from '../domain/Point';
import * as ScoreMultiplier from '../domain/ScoreMultiplier';

test('', () => {

  // let point = mkPoint(1, 5);
  // let bad = scoreMultiplier(point, 15);
  // console.log(stringify(bad));
  let multipliers = mkMultiplierGrid(15);
  let eq = ScoreMultiplier.eq;
  // console.log(`${stringify(multipliers.rows())}`);

  const multiplier = function(row, col) {
    return multipliers.getElement(mkPoint(row, col));
  };

  let x1 = ScoreMultiplier.noMultiplier();
  let xWord = ScoreMultiplier.wordMultiplier;
  let xLetter = ScoreMultiplier.letterMultiplier;

  expect(eq(multiplier(0, 0), xWord(3))).toBe(true);
  expect(eq(multiplier(0, 1), x1)).toBe(true);
  expect(eq(multiplier(0, 2), x1)).toBe(true);
  expect(eq(multiplier(0, 3), xLetter(2))).toBe(true);
  expect(eq(multiplier(0, 4), x1)).toBe(true);
  expect(eq(multiplier(0, 5), x1)).toBe(true);
  expect(eq(multiplier(0, 6), x1)).toBe(true);
  expect(eq(multiplier(0, 7), xWord(3))).toBe(true);

  expect(eq(multiplier(1, 0), x1)).toBe(true);
  expect(eq(multiplier(1, 1), xWord(2))).toBe(true);
  expect(eq(multiplier(1, 2), x1)).toBe(true);
  expect(eq(multiplier(1, 3), x1)).toBe(true);
  expect(eq(multiplier(1, 4), x1)).toBe(true);
  expect(eq(multiplier(1, 5), xLetter(3))).toBe(true);
  expect(eq(multiplier(1, 6), x1)).toBe(true);
  expect(eq(multiplier(1, 7), x1)).toBe(true);



  expect(eq(multiplier(7, 7), x1)).toBe(true);
});