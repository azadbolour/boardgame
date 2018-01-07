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
  ) where

import BoardGame.Common.Domain.Point (Point, Point(Point), Axis, Coordinate, Height, Width)
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Point as Point
import qualified BoardGame.Common.Domain.Grid as Grid
import BoardGame.Common.Domain.Grid (Grid, Grid(Grid))

data SwissCheeseGrid val = SwissCheeseGrid {
    height :: Height
  , width :: Width
  , cells :: [[(Point, Maybe val)]]
  , get :: Point -> Maybe val
  , set :: Point -> Maybe val -> SwissCheeseGrid val
}

mkSwissCheeseGrid :: (Height -> Width -> Maybe val) -> Height -> Width -> SwissCheeseGrid val
mkSwissCheeseGrid cellMaker height width =
  let pointedCellMaker row col = (Point row col, cellMaker row col)
      grid = Grid.mkGrid pointedCellMaker height width
  in mkInternal grid

mkInternal :: Grid (Point, Maybe val) -> SwissCheeseGrid val
mkInternal grid @ Grid {height, width, cells} =
  SwissCheeseGrid height width cells get set
    where get point = do
            (_, maybeVal) <- Grid.get grid point
            maybeVal
          set point value =
            let grid' = Grid.set grid point (point, value)
            in mkInternal grid'

