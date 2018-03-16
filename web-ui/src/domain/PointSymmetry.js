/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * Symmetry transformations for board square.
 */

import {mkPoint} from "./Point";

export const reflectOnFirstOctant = function (point) {
  let p = reflectOnPositiveQuadrant(point);
  let {row, col} = p;
  if (row <= col)
    return p;
  else
    return mkPoint(col, row);
};

export const reflectOnPositiveQuadrant = function (point) {
  return mkPoint(Math.abs(point.row), Math.abs(point.col));
};

export const translateOrigin = function (origin, point) {
  return mkPoint(point.row - origin.row, point.col - origin.col);
};
