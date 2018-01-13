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

module Bolour.Grid.SparseGrid (
      SparseGrid
    , mkGrid
    , mkEmptyGrid
    , height
    , width
    , rows
    , cols
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
    , lineSegments
  ) where

import Data.List
import Data.Maybe (isJust, fromJust, isNothing)
import Control.Monad (join)
import qualified Bolour.Util.Empty as Empty
import Bolour.Grid.Point (Point, Point(Point), Axis, Coordinate, Height, Width)
import qualified Bolour.Grid.Point as Axis
import qualified Bolour.Grid.Point as Point
import qualified Bolour.Grid.Grid as Grid
import Bolour.Grid.Grid (Grid, Grid(Grid))

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
--   the LocatedValue representation.
data SparseGrid val = SparseGrid {
    -- | Grid height: number of rows.
    height :: Height
    -- | Grid width: number of columns.
  , width :: Width
    -- 2D array of all located values by row.
  , rows :: [[LocatedValue val]]
    -- 2D array of all located values by col.
  , cols :: [[LocatedValue val]]
  , get :: Point -> Maybe val
    -- | Get the non-empty values in the grid together with their locations.
  , getJusts :: [(val, Point)]
    -- | Set the value of a point on the grid.
  , set :: Point -> Maybe val -> SparseGrid val
    -- | Set multiple values.
  , setN :: [(Maybe val, Point)] -> SparseGrid val
    -- | Get the next located value on a grid line. Axis X/Y horizontal/vertical.
    --   Nothing means the point has no next (is the last point on a line).
  , next :: Point -> Axis -> Maybe (LocatedValue val)
    -- | Get the previous located value on a grid line. Axis X/Y horizontal/vertical.
    --   Nothing means the point has no next (is the first point on a line).
  , prev :: Point -> Axis -> Maybe (LocatedValue val)
    -- | Get an adjacent located value on a grid line in a given direction.
    --   Axis X/Y horizontal/vertical. Direction Axis.forward or Axis.backward.
    --   Nothing means the point does not have the requested neighbor (is on a boundary).
  , adjacent :: Point -> Axis -> Int -> Maybe (LocatedValue val)
    -- | The point is empty or does not exist in the grid.
    --   Intended to simplify the use case where the caller knows the point exists.
  , pointIsEmpty :: Point -> Bool
    -- | The point is isolated in its horizontal (X) or vertical (Y) line.
    --   It has no neighbors on either side on the line.
  , isolatedInLine :: Point -> Axis -> Bool
    -- | The point exists on the grid.
  , inBounds :: Point -> Bool
    -- | Get the farthest neighbor of a point along a given axis in a given direction.
    --
    --   Given a point p on a line, a point q on that line
    --   is considered to be a neighbor of p if there is a contiguous
    --   non-empty line segment between p and q (excluding p itself).
    --   Axis X/Y horizontal/vertical. Direction Axis.forward or Axis.backward.
    --   The point itself is considered a degenerate neighbour if it has no
    --   line neighbor in the given direction.
  , farthestNeighbor :: Point -> Axis -> Int -> Point
    -- | Get the number of lines of the grid parallel to a given axis:
    --   X (number of horizontal lines: height), Y (number of vertical lines: width).
  , numLines :: Axis -> Int
    -- | Get the range of non-empty points surrounding a point on a line.
    --   The point itself is always counted as part of the range whether
    --   not it is empty.
  , surroundingRange :: Point -> Axis -> [Point]
    -- | Get a list of all horizontal or vertical line segments
    --   of the grid.
    --
    --   Returns: [(axis, lineNumber, start, size, [Maybe val])]
  , lineSegments :: [(Axis, Coordinate, Coordinate, Int, [Maybe val])]
}

instance (Show val) => Show (SparseGrid val)
  where show SparseGrid {rows} = show rows

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
      (Grid.rows grid)
      (Grid.cols grid)
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
      (lineSegments' grid)

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

lineSegments' :: Grid' val -> [(Axis, Coordinate, Coordinate, Int, [Maybe val])]
lineSegments' grid = lineSegmentsAlong grid Axis.X ++ lineSegmentsAlong grid Axis.Y

lineSegmentsAlong :: Grid' val -> Axis -> [(Axis, Coordinate, Coordinate, Int, [Maybe val])]
lineSegmentsAlong Grid {rows, height, width} axis =
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

