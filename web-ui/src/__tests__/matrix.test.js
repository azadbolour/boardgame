/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {mkMatrix} from '../domain/Matrix';
import {mkPoint} from '../domain/Point';

test('matrix set and get element', () => {
  let rows = [[1, 2], [3, 4]];
  let matrix = mkMatrix(2, rows);
  let point = mkPoint(0, 0);
  let value = matrix.getElement(point);
  expect(value).toBe(1);

  let sum = matrix.reduce(function(acc, value) {return acc + value; }, 0);
  expect(sum).toBe(10);

  let $matrix = matrix.updateRow(1, [10, 20]);
  expect($matrix.getElement(mkPoint(1, 1))).toBe(20);
  expect(matrix.getElement(mkPoint(1, 1))).toBe(4);
});

test('matrix get column', () => {
  let rows = [[1, 2], [3, 4]];
  let matrix = mkMatrix(2, rows);
  let point00 = mkPoint(0, 0);
  let value = matrix.getElement(point00);
  expect(value).toBe(1);
  let point10 = mkPoint(1, 0);
  expect(matrix.getElement(point10)).toBe(3);
  let cols = matrix.cols();
  expect(cols[0][0]).toBe(1);
  expect(cols[0][1]).toBe(3);
});