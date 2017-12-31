--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Common.Domain.PointSymmetry (
    reflectOnFirstOctant
  , reflectOnPositiveQuadrant
  , translateOrigin
  ) where

import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point

reflectOnFirstOctant :: Point -> Point
reflectOnFirstOctant point =
  let p @ Point {row, col} = reflectOnPositiveQuadrant point
  in if row <= col then p else Point row col

reflectOnPositiveQuadrant :: Point -> Point
reflectOnPositiveQuadrant point @ Point {row, col} = Point (abs row) (abs col)

translateOrigin :: Point -> Point -> Point
translateOrigin origin point =
  Point (Point.row point - Point.row origin) (Point.col point - Point.col origin)


