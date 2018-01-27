/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import {mkPoint} from "./Point";
import * as Point from "./Point";
import * as Symmetry from "./PointSymmetry";
import {mkMatrixFromCoordinates} from "./Matrix";

/**
 * Values of points.
 */

/**
 * Points may have values between 1 and 5.
 */
const maxValue = 5;

/**
 * Probability of higher values decreases for higher values.
 */
const valueDistribution = [
  81,
  81 + 27,
  81 + 27 + 13,
  81 + 27 + 13 + 8,
  81 + 27 + 13 + 8 + 4
];
const maxDistribution = (81 + 25 + 13 + 8 + 4) + 2;

const exponentialRandomValue = function() {
  let d = Math.floor(Math.random() * maxDistribution);
  for (let i = 0; i < maxValue; i++)
    if (valueDistribution[i] >= d)
      return i + 1;
};

export const mkValueFactory = function(dimension) {
  let _center = Math.floor(dimension / 2);

  // Make a list of all points in the first octant.
  let _firstOctantPoints = [];
  for (let row = 0; row <= _center; row++)
    for (let col = row; col <= _center; col++)
      _firstOctantPoints.push(mkPoint(row, col));

  // Make a parallel list of values for the the above points.
  let _firstOctantValues = [];
  for (let i = 0; i < _firstOctantPoints.length; i++) {
    let value = exponentialRandomValue();
    _firstOctantValues.push(value);
  }

  let _findFirstOctantIndex = function(point) {
    let centerPoint = mkPoint(_center, _center);
    let pointRelativeToCenter = Symmetry.translateOrigin(centerPoint, point);
    let firstOctantPoint = Symmetry.reflectOnFirstOctant(pointRelativeToCenter);
    return _firstOctantPoints.findIndex(
      element => Point.eq(element, firstOctantPoint)
    );
  };

  return {
    valueOf: function(point) {
      let index = _findFirstOctantIndex(point);
      return _firstOctantValues[index];
    },

    mkValueGrid: function () {
      let it = this;
      let grid = mkMatrixFromCoordinates(dimension, function(row, col) {
        return it.valueOf(mkPoint(row, col));
      });
      return grid;
    },

    mkEmptyValueGrid: function() {
      return mkMatrixFromCoordinates(dimension, function(row, col) {
        return 1;
      });
    }
  }

};


