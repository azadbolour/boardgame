// Translated by hand from Scala. See Scala version for comments.

import {mkMatrixFromCoordinates} from "./Matrix";
import {mkPoint} from "./Point";
import * as Point from './Point';

export const ScoreMultiplierType = {
  Letter: "Letter",
  Word: "Word",
  None: "None"
};

export const mkScoreMultiplier = function(multiplierType, factor) {
  return {
    multiplierType,
    factor
  };
};

const noMultiplier = function() {
  return mkScoreMultiplier(ScoreMultiplierType.None, 1);
};
const letterMultiplier = function(factor) {
  return mkScoreMultiplier(ScoreMultiplierType.Letter, factor);
};
const wordMultiplier = function(factor) {
  return mkScoreMultiplier(ScoreMultiplierType.Word, factor);
};

export const mkMultiplierGrid = function (dimension) {
  const cellScoreMultiplier = function (row, col) {
    return scoreMultiplier(mkPoint(row, col), dimension)
  };

  const scoreMultiplier = function (point, dimension) {
    let center = Math.floor(dimension / 2);
    let centerPoint = mkPoint(center, center);
    let pointRelativeToCenter = translateOrigin(centerPoint, point);
    return multiplierRelativeToCenter(pointRelativeToCenter, dimension);
  };

  const multiplierRelativeToCenter = function (point, dimension) {
    let representative = reflectOnFirstOctant(point);
    return multiplierForFirstOctantRelativeToCenter(representative, dimension);
  };

  const multiplierForFirstOctantRelativeToCenter = function (point, dimension) {
    let bound = Math.floor(dimension / 2);
    let {row, col} = point;

    const isCornerPoint = Point.eq(point, mkPoint(bound, bound));
    const isMidEdgePoint = Point.eq(point, mkPoint(0, bound));
    const isCenterPoint = Point.eq(point, mkPoint(0, 0));
    const isQuarterEdgePoint = row == bound / 2 + 1 && col == bound;
    const isDiagonalPoint = function (centerOffset) {
      return col - row == centerOffset
    };

    const multiplier = function () {
      if (isCenterPoint) return noMultiplier();
      else if (isCornerPoint) return wordMultiplier(3);
      else if (isMidEdgePoint) return wordMultiplier(3);
      else if (isQuarterEdgePoint) return letterMultiplier(2);
      else if (isDiagonalPoint(0)) {
        switch (row) {
          case 1:
            return letterMultiplier(2);
          case 2:
            return letterMultiplier(3);
          default:
            return wordMultiplier(2);
        }
      }
      else if (isDiagonalPoint(bound / 2 + 1)) {
        let nextToMiddle = bound - 1;
        switch (col) {
          case bound:
            return noMultiplier();
          case nextToMiddle:
            return letterMultiplier(3);
          default:
            return letterMultiplier(2);
        }
      }
      else return noMultiplier();
    };

    return multiplier();
  };

  const reflectOnFirstOctant = function (point) {
    let p = reflectOnPositiveQuadrant(point);
    let {row, col} = p;
    if (row <= col)
      return p;
    else
      return mkPoint(col, row);
  };

  const reflectOnPositiveQuadrant = function (point) {
    return mkPoint(Math.abs(point.row), Math.abs(point.col));
  };

  const translateOrigin = function (origin, point) {
    return mkPoint(point.row - origin.row, point.col - origin.col);
  };

  let grid = mkMatrixFromCoordinates(dimension, function(row, col) {
    return scoreMultiplier(mkPoint(row, col), dimension);
  });
  return grid;
};