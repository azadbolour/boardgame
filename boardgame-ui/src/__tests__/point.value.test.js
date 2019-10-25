
/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import {stringify} from "../util/Logger";
import {mkPoint} from '../domain/Point';
import * as PointValue from '../domain/PointValue';

test('', () => {

  let factory = PointValue.mkValueFactory(15);
  let value = function(row, col) {
    return factory.valueOf(mkPoint(row, col));
  };

  expect(value(0, 0)).toBeGreaterThan(0);
  expect(value(0, 14)).toBeGreaterThan(0);
  expect(value(14, 0)).toBeGreaterThan(0);
  expect(value(14, 14)).toBeGreaterThan(0);

  let grid = factory.mkValueGrid();
  let gridValue = function(row, col) {
    return grid.getElement(mkPoint(row, col));
  };

  expect(gridValue(0, 0)).toBeGreaterThan(0);
  expect(gridValue(0, 14)).toBeGreaterThan(0);
  expect(gridValue(14, 0)).toBeGreaterThan(0);
  expect(gridValue(14, 14)).toBeGreaterThan(0);



});