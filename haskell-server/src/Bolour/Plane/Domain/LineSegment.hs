--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module Bolour.Plane.Domain.LineSegment (
    LineSegment(..)
  ) where

import Bolour.Plane.Domain.Axis (Axis)
import qualified Bolour.Plane.Domain.Axis as Axis
import Bolour.Plane.Domain.Point (Point, Point(Point))

-- | A line segment within a 2-dimensional grid.
--   Each point of a line segment may or may not have a value (represented as Maybe val).
data LineSegment val = LineSegment {
    -- | The direction of the line segment - along the X or Y axis.
    axis :: Axis
    -- | The line number among all grid lines along the same direction.
  , lineNumber :: Int
    -- | The index of the beginning point of this line segment along its line within the grid.
  , begin :: Int
    -- | The index of the end point of this line segment along its line within the grid.
  , end :: Int
    -- | The values/non-values of the points in this line segment.
  , segment :: [Maybe val]
}

row :: LineSegment val -> Int -> Int
row LineSegment { axis, lineNumber, begin } offset =
  case axis of
    Axis.X -> lineNumber
    Axis.Y -> begin + offset

column :: LineSegment val -> Int -> Int
column LineSegment { axis, lineNumber, begin } offset =
  case axis of
    Axis.X -> begin + offset
    Axis.Y -> lineNumber

pointAt :: LineSegment val -> Int -> Point
pointAt line offset = Point (row line offset) (column line offset)




