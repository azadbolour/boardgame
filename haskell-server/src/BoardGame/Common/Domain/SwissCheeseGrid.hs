--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}

module BoardGame.Common.Domain.SwissCheeseGrid (
      SwissCheeseGrid
    , mkSwissCheeseGrid
    , height
    , width
    , cells
    , get
    , set
    , next
    , prev
    , adjacent
    , inBounds
  ) where

import BoardGame.Common.Domain.Point (Point, Point(Point), Axis, Coordinate, Height, Width)
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Point as Point
import qualified BoardGame.Common.Domain.Grid as Grid
import BoardGame.Common.Domain.Grid (Grid, Grid(Grid))

type LocatedValue val = (Maybe val, Point)

data SwissCheeseGrid val = SwissCheeseGrid {
    height :: Height
  , width :: Width
  , cells :: [[LocatedValue val]]
  , get :: Point -> Maybe val
  , set :: Point -> Maybe val -> SwissCheeseGrid val
  , next :: Point -> Axis -> Maybe val
  , prev :: Point -> Axis -> Maybe val
  , adjacent :: Point -> Axis -> Int -> Maybe val
  , inBounds :: Point -> Bool
}

instance (Show val) => Show (SwissCheeseGrid val)
  where show SwissCheeseGrid {cells} = show cells

mkSwissCheeseGrid :: (Height -> Width -> Maybe val) -> Height -> Width -> SwissCheeseGrid val
mkSwissCheeseGrid cellMaker height width =
  let pointedCellMaker row col = (cellMaker row col, Point row col)
      grid = Grid.mkGrid pointedCellMaker height width
  in mkInternal grid

mkInternal :: Grid (LocatedValue val) -> SwissCheeseGrid val
mkInternal grid @ Grid {height, width, cells} =
  SwissCheeseGrid height width cells get set next prev adjacent inBounds
    where get point = do
            (maybeVal, _) <- Grid.get grid point
            maybeVal
          set point value =
            let grid' = Grid.set grid point (value, point)
            in mkInternal grid'
          next point axis = do
            (maybeVal, _) <- Grid.next grid point axis
            maybeVal
          prev point axis = do
            (maybeVal, _) <- Grid.prev grid point axis
            maybeVal
          adjacent point axis direction =
            let calcAdj = if direction == 1 then next else prev
            in calcAdj point axis
          inBounds = Grid.inBounds grid


