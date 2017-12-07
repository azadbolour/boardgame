
/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import {stringify} from "../util/Logger";
import {mkMultiplierGrid, ScoreMultiplierType} from '../domain/ScoreMultiplier';
import {mkPoint} from '../domain/Point';
import * as Point from '../domain/Point';

test('', () => {
  let multipliers = mkMultiplierGrid(15);
  // console.log(`${stringify(multipliers.rows())}`);

  const multiplier = function(row, col) {
    return multipliers.getElement(mkPoint(row, col));
  };

  expect(multiplier(7, 7).factor).toBe(1);
  expect(multiplier(0, 0).factor).toBe(3);
  expect(multiplier(0, 7).factor).toBe(3);
  expect(multiplier(0, 7).multiplierType).toBe(ScoreMultiplierType.Word);

});