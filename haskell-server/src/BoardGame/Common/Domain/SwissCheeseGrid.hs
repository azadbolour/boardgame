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
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}

module BoardGame.Common.Domain.SwissCheeseGrid (
      SwissCheeseGrid
    , mkGrid
    , mkEmptyGrid
    , height
    , width
    , cells
    , get
    , getJusts
    , set
    , setN
    , next
    , prev
    , adjacent
    , isolatedInLine
    , inBounds
  ) where

import Data.List
import Data.Maybe (isJust, fromJust, isNothing)
import Control.Monad (join)
import qualified Bolour.Util.Empty as Empty
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
  , getJusts :: [(val, Point)]
  , set :: Point -> Maybe val -> SwissCheeseGrid val
  , setN :: [(Maybe val, Point)] -> SwissCheeseGrid val
  , next :: Point -> Axis -> Maybe (LocatedValue val)
  , prev :: Point -> Axis -> Maybe (LocatedValue val)
  , adjacent :: Point -> Axis -> Int -> Maybe (LocatedValue val)
  , pointIsEmpty :: Point -> Bool
  , isolatedInLine :: Point -> Axis -> Bool
  , inBounds :: Point -> Bool
  , farthestNeighbor :: Point -> Axis -> Int -> Maybe (LocatedValue val)
}

instance (Show val) => Show (SwissCheeseGrid val)
  where show SwissCheeseGrid {cells} = show cells

instance Empty.Empty (Maybe (LocatedValue val))
  where isEmpty x = isNothing $ join $ fst <$> x

instance Empty.Empty (SwissCheeseGrid val)
  where isEmpty = null . getJusts

instance Empty.Empty (Maybe val, Point)
  where isEmpty x = let maybe = fst x in isNothing maybe


mkGrid :: (Height -> Width -> Maybe val) -> Height -> Width -> SwissCheeseGrid val
mkGrid cellMaker height width =
  let pointedCellMaker row col = (cellMaker row col, Point row col)
      grid = Grid.mkGrid pointedCellMaker height width
  in mkInternal grid

mkEmptyGrid :: Height -> Width -> SwissCheeseGrid val
mkEmptyGrid = mkGrid (\height width -> Nothing)

mkInternal :: Grid (LocatedValue val) -> SwissCheeseGrid val

mkInternal grid =
  SwissCheeseGrid
      (Grid.height grid)
      (Grid.width grid)
      (Grid.cells grid)
      (get' grid)
      (getJusts' grid)
      (set' grid)
      (setN' grid)
      (Grid.next grid)
      (Grid.prev grid)
      (adjacent' grid)
      (pointIsEmpty' grid)
      (isolatedInLine' grid)
      (Grid.inBounds grid)
      (farthestNeighbor' grid)

type Grid' val = Grid (LocatedValue val)

get' :: Grid' val -> Point -> Maybe val
get' grid point = do
  (maybeVal, _) <- Grid.get grid point
  maybeVal

set' :: Grid' val -> Point -> Maybe val -> SwissCheeseGrid val
set' grid point value = mkInternal $ Grid.set grid point (value, point)

adjacent' :: Grid' val -> Point -> Axis -> Int -> Maybe (LocatedValue val)
adjacent' grid point axis direction =
  (if direction == 1 then Grid.next else Grid.prev) grid point axis

setN' :: Grid' val -> [(Maybe val, Point)] -> SwissCheeseGrid val
setN' grid locatedValues =
  mkInternal (Grid.setN grid (addPoint <$> locatedValues))
    where addPoint (value, point) = ((value, point), point)

getJusts' :: Grid' val -> [(val, Point)]
getJusts' grid =
  let justs = filter (isJust . fst) (Grid.concatGrid grid)
      unjust (just, point) = (fromJust just, point)
  in unjust <$> justs

pointIsEmpty' :: Grid' val -> Point -> Bool
pointIsEmpty' grid = isNothing . get' grid

isolatedInLine' :: Grid' val -> Point -> Axis -> Bool
isolatedInLine' grid point axis =
  Empty.isEmpty (Grid.next grid point axis)
    && Empty.isEmpty (Grid.prev grid point axis)

farthestNeighbor' :: Grid' val -> Point -> Axis -> Int -> Maybe (LocatedValue val)
farthestNeighbor' grid point axis direction = Nothing -- TODO. Implement.

