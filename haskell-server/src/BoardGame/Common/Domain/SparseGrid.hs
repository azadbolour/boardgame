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

module BoardGame.Common.Domain.SparseGrid (
      SparseGrid
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
    , farthestNeighbor
    , numLines
    , surroundingRange
    , strips
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

-- | A grid that may have some empty slots.
--
--   The term 'sparse' is used to signify that this grid is aware of
--   emptiness in some slots, not that there are necessarily
--   relatively few non-empty slots.
--
--   The slots of a sparse grid have the type:
--      LocatedValue: (Maybe val, Point).
--
--   This allows compact implementations of a sparse grid in
--   cases where the grid is in fact expected to be sparse.
--   The current implementation in this module, however,
--   is not a 'sparse' implementation as such. But it retains
--   the LocatedValue representation in its interface.
data SparseGrid val = SparseGrid {
    height :: Height
  , width :: Width
  , cells :: [[LocatedValue val]]
  , get :: Point -> Maybe val
  , getJusts :: [(val, Point)]
  , set :: Point -> Maybe val -> SparseGrid val
  , setN :: [(Maybe val, Point)] -> SparseGrid val
  , next :: Point -> Axis -> Maybe (LocatedValue val)
  , prev :: Point -> Axis -> Maybe (LocatedValue val)
  , adjacent :: Point -> Axis -> Int -> Maybe (LocatedValue val)
  , pointIsEmpty :: Point -> Bool
  , isolatedInLine :: Point -> Axis -> Bool
  , inBounds :: Point -> Bool
  -- Point itself is considered a degenerate neighbour.
  , farthestNeighbor :: Point -> Axis -> Int -> Point
  , numLines :: Axis -> Int
  , surroundingRange :: Point -> Axis -> [Point]
  , strips :: [(Axis, Coordinate, Coordinate, Int, [Maybe val])]
}

instance (Show val) => Show (SparseGrid val)
  where show SparseGrid {cells} = show cells

instance Empty.Empty (Maybe (LocatedValue val))
  where isEmpty x = isNothing $ join $ fst <$> x

instance Empty.Empty (SparseGrid val)
  where isEmpty = null . getJusts

instance Empty.Empty (Maybe val, Point)
  where isEmpty x = let maybe = fst x in isNothing maybe

forward = Axis.forward
backward = Axis.backward

mkGrid :: (Height -> Width -> Maybe val) -> Height -> Width -> SparseGrid val
mkGrid cellMaker height width =
  let pointedCellMaker row col = (cellMaker row col, Point row col)
      grid = Grid.mkGrid pointedCellMaker height width
  in mkInternal grid

mkEmptyGrid :: Height -> Width -> SparseGrid val
mkEmptyGrid = mkGrid (\height width -> Nothing)

mkInternal :: Grid (LocatedValue val) -> SparseGrid val

mkInternal grid =
  SparseGrid
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
      (Grid.numLines grid)
      (surroundingRange' grid)
      (strips' grid)

type Grid' val = Grid (LocatedValue val)

get' :: Grid' val -> Point -> Maybe val
get' grid point = do
  (maybeVal, _) <- Grid.get grid point
  maybeVal

set' :: Grid' val -> Point -> Maybe val -> SparseGrid val
set' grid point value = mkInternal $ Grid.set grid point (value, point)

adjacent' :: Grid' val -> Point -> Axis -> Int -> Maybe (LocatedValue val)
adjacent' grid point axis direction =
  (if direction == 1 then Grid.next else Grid.prev) grid point axis

setN' :: Grid' val -> [(Maybe val, Point)] -> SparseGrid val
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

pointIsNonEmpty' :: Grid' val -> Point -> Bool
pointIsNonEmpty' grid point = not (pointIsEmpty' grid point)

isolatedInLine' :: Grid' val -> Point -> Axis -> Bool
isolatedInLine' grid point axis =
  Empty.isEmpty (Grid.next grid point axis)
    && Empty.isEmpty (Grid.prev grid point axis)

nonEmptyToEmptyTransitionPoint :: Grid' val -> Point -> Axis -> Int -> Bool
nonEmptyToEmptyTransitionPoint grid point axis direction =
  let dimension = Grid.numLines grid axis
      maybeAdjLocatedValue = adjacent' grid point axis direction
  in pointIsNonEmpty' grid point && Empty.isEmpty maybeAdjLocatedValue

-- | Point itself is considered a degenerate neighbor.
farthestNeighbor' :: Grid' val -> Point -> Axis -> Int -> Point
farthestNeighbor' grid point axis direction =
   if Empty.isEmpty $ adjacent' grid point axis direction then point
   else fromJust $ find nonEmptyToEmpty neighbors
      where
        nonEmptyToEmpty pnt = nonEmptyToEmptyTransitionPoint grid pnt axis direction
        dimension = Grid.numLines grid axis
        neighbors = Point.nthNeighbor point axis direction <$> [1 .. dimension - 1]

surroundingRange' :: Grid' val -> Point -> Axis -> [Point]
surroundingRange' grid point axis =
  let rangeLimit = farthestNeighbor' grid point axis
      Point {row = row1, col = col1} = rangeLimit backward
      Point {row = rowN, col = colN} = rangeLimit forward
  in case axis of
       Axis.X -> Point row1 <$> [col1 .. colN]
       Axis.Y -> flip Point col1 <$> [row1 .. rowN]

strips' :: Grid' val -> [(Axis, Coordinate, Coordinate, Int, [Maybe val])]
strips' grid = stripsAlong grid Axis.X ++ stripsAlong grid Axis.Y

stripsAlong :: Grid' val -> Axis -> [(Axis, Coordinate, Coordinate, Int, [Maybe val])]
stripsAlong Grid {cells = rows, height, width} axis =
  let lineCoordinates Point {row, col} =    -- (lineNumber, offset)
        case axis of
          Axis.X -> (row, col)
          Axis.Y -> (col, row)
      (lines, len) =
        case axis of
          Axis.X -> (rows, width)
          Axis.Y -> (transpose rows, height)
  in do
       line <- lines
       begin <- [0 .. len - 1]
       size <- [1 .. len - begin]
       let segment = take size (drop begin line)
       let content = fst <$> segment
       let (lineNumber, offset) = lineCoordinates $ snd $ head segment
       return (axis, lineNumber, offset, size, content)

