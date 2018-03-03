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

module Bolour.Plane.Domain.BlackWhiteGrid (
    BlackWhiteGrid(..)
  , mkGrid
  , mkEmptyGrid
  )
  where

import Data.List
import Data.Maybe (isJust, isNothing, fromJust, catMaybes)

import Bolour.Util.BlackWhite
import qualified Bolour.Util.Empty as Empty
import Bolour.Plane.Domain.Grid (Grid)
import qualified Bolour.Plane.Domain.Grid as Grid
import qualified Bolour.Plane.Domain.Axis as Axis
import qualified Bolour.Plane.Domain.Point as Point
import Bolour.Plane.Domain.Axis (Axis, Height, Width, Direction)
import Bolour.Plane.Domain.Point (Point, Point(Point))
import Bolour.Plane.Domain.BlackWhitePoint(BlackWhitePoint, BlackWhitePoint(BlackWhitePoint))
import qualified Bolour.Plane.Domain.BlackWhitePoint as BlackWhitePoint

data BlackWhiteGrid val = BlackWhiteGrid {
    height :: Height
  , width :: Width
  , rows :: [[BlackWhitePoint val]]
  , cols :: [[BlackWhitePoint val]]
  -- | Get the cell value of a point - if the point is out of bounds get Black.
  , get :: Point -> BlackWhite val
  -- | Get the real values (White and 'Just') of the grid together with their locations.
  , getValues :: [(val, Point)]
  -- | Update the value of a point on the grid.
  , set :: Point -> BlackWhite val -> BlackWhiteGrid val
  , setN :: [BlackWhitePoint val] -> BlackWhiteGrid val
  -- | Get the value and location of the next point along an axis, if any.
  --   Nothing means next is out of bounds.
  , next :: Point -> Axis -> Maybe (BlackWhitePoint val)
  , prev :: Point -> Axis -> Maybe (BlackWhitePoint val)
  , adjacent :: Point -> Axis -> Direction -> Maybe (BlackWhitePoint val)

  , isBlack :: Point -> Bool
  , isWhite :: Point -> Bool
  , isEmpty :: Point -> Bool
  , hasValue :: Point -> Bool
  -- | The point is isolated in its horizontal (X) or vertical (Y) line.
  --   It has no neighbors on either side on the line.
  -- , isIsolatedInLine :: Point -> Axis -> Bool
  , inBounds :: Point -> Bool
    -- | Get the farthest neighbor of a point along a given axis
    --   in a given direction.
    --   Given a point p on a line, a point q on that line
    --   is considered to be a neighbor of p if there is a contiguous
    --   non-empty white line segment between p and q (excluding p itself).
    --   Axis X/Y horizontal/vertical. Direction Axis.forward or Axis.backward.
    --   The point itself is considered a degenerate neighbour.
  , farthestNeighbor :: Point -> Axis -> Direction -> Point
    -- | Get the number of lines of the grid parallel to a given axis:
    --   X (number of horizontal lines: height), Y (number of vertical lines: width).
  , numLines :: Axis -> Int
    -- | Get the range of non-empty white points surrounding a point on a line.
    --   The point itself is always counted as part of the range whether or
    --   not it is empty.
  , surroundingRange :: Point -> Axis -> [Point]
}

instance (Show val) => Show (BlackWhiteGrid val)
  where show BlackWhiteGrid {rows} = show rows

instance Empty.Empty (BlackWhiteGrid val)
  where isEmpty BlackWhiteGrid {rows} = all Empty.isEmpty (concat rows)

instance Empty.Empty (Maybe val, Point)
  where isEmpty x = let maybe = fst x in isNothing maybe

mkGrid :: (Height -> Width -> BlackWhite val) -> Height -> Width -> BlackWhiteGrid val
mkGrid cellMaker height width =
  let pointedCellMaker row col = BlackWhitePoint (cellMaker row col) (Point row col)
      grid = Grid.mkGrid pointedCellMaker height width
  in mkInternal grid

mkEmptyGrid :: Height -> Width -> BlackWhiteGrid val
mkEmptyGrid = mkGrid (\height width -> White Nothing)

type Grid' val = Grid (BlackWhitePoint val)

mkInternal :: Grid' val -> BlackWhiteGrid val

mkInternal grid =
  BlackWhiteGrid
      (Grid.height grid)
      (Grid.width grid)
      (Grid.rows grid)
      (Grid.cols grid)

      (get' grid)
      (getValues' grid)
      (set' grid)
      (setN' grid)

      (next' grid)
      (prev' grid)
      (adjacent' grid)

      (isBlack' grid)
      (isWhite' grid)
      (isEmpty' grid)
      (hasValue' grid)
      -- (isIsolatedInLine' grid)
      (Grid.inBounds grid)

      (farthestNeighbor' grid)
      (Grid.numLines grid)
      (surroundingRange' grid)

get' :: Grid' val -> Point -> BlackWhite val
get' grid point =
  let maybeBlackWhitePoint = Grid.get grid point
  in case maybeBlackWhitePoint of
     Nothing -> Black
     Just BlackWhitePoint {value} -> value

fromJustWhites :: [BlackWhitePoint val] -> [(val, Point)]
fromJustWhites bwPoints =
  let maybePair BlackWhitePoint {value = bw, point} =
               let maybe = fromWhite bw
               in case maybe of
                  Nothing -> Nothing
                  Just v -> Just (v, point)
  in catMaybes $ maybePair <$> bwPoints

getValues' :: Grid' val -> [(val, Point)]
getValues' grid = fromJustWhites (Grid.concatGrid grid)

set' :: Grid' val -> Point -> BlackWhite val -> BlackWhiteGrid val
set' grid point value = mkInternal $ Grid.set grid point (BlackWhitePoint value point)

setN' :: Grid' val -> [BlackWhitePoint val] -> BlackWhiteGrid val
setN' grid bwPoints =
  mkInternal (Grid.setN grid (addPoint <$> bwPoints))
    where addPoint bwPoint @ BlackWhitePoint {value, point} = (bwPoint, point)

-- | When a related cell is Black, it is as if no related cell exists, and so
--   convert it to Nothing, the same as if a related cell is out of bounds.
-- unwindBlackWhite :: Maybe (BlackWhitePoint val) -> Maybe (Maybe val, Point)
-- unwindBlackWhite maybe =
--   case maybe of
--        Nothing -> Nothing
--        Just bwPoint ->
--          case bwPoint of
--          BlackWhitePoint {value, point} ->
--            case value of
--            Black -> Nothing
--            White maybeVal -> Just (maybeVal, point)

next' :: Grid' val -> Point -> Axis -> Maybe (BlackWhitePoint val)
next' grid point axis = Grid.next grid point axis

prev' :: Grid' val -> Point -> Axis -> Maybe (BlackWhitePoint val)
prev' grid point axis = Grid.prev grid point axis

adjacent' :: Grid' val -> Point -> Axis -> Direction -> Maybe (BlackWhitePoint val)
adjacent' grid point axis direction = Grid.adjacentCell grid point axis direction

-- | Out of bounds is considered to be black!
isBlack' :: Grid' val -> Point -> Bool
isBlack' grid point =
  let bw = get' grid point
  in case bw of
     Black -> True
     _ -> False

isWhite' :: Grid' val -> Point -> Bool
isWhite' grid point = not (isBlack' grid point)

isEmpty' :: Grid' val -> Point -> Bool
isEmpty' grid point =
  let bw = get' grid point
  in case bw of
     Black -> False
     White maybe -> isNothing maybe

hasValue' :: Grid' val -> Point -> Bool
hasValue' grid point =
  let bw = get' grid point
  in isJustWhite bw

-- isIsolatedInLine' :: Grid' val -> Point -> Axis -> Bool
-- isIsolatedInLine' grid point axis =
--   let maybeNext = do (maybe, _) <- next' grid point axis; maybe
--       maybePrev = do (maybe, _) <- prev' grid point axis; maybe
--   in isNothing maybeNext && isNothing maybePrev

adjHasValue :: Grid' val -> Point -> Axis -> Int -> Bool
adjHasValue grid point axis direction =
  let maybe = do
                BlackWhitePoint {value} <- adjacent' grid point axis direction
                fromWhite value
  in isJust maybe

valuedNotValuedTransitionPoint :: Grid' val -> Point -> Axis -> Int -> Bool
valuedNotValuedTransitionPoint grid point axis direction =
  let adjacentHasValue = adjHasValue grid point axis direction
  in hasValue' grid point && not adjacentHasValue

-- | Point itself is considered a degenerate neighbor.
farthestNeighbor' :: Grid' val -> Point -> Axis -> Int -> Point
farthestNeighbor' grid point axis direction =
   if not (adjHasValue grid point axis direction) then point
   else fromJust $ find valuedToNotValued neighbors
      where
        valuedToNotValued pnt = valuedNotValuedTransitionPoint grid pnt axis direction
        dimension = Grid.numLines grid axis
        neighbors = Point.nthNeighbor point axis direction <$> [1 .. dimension - 1]

surroundingRange' :: Grid' val -> Point -> Axis -> [Point]
surroundingRange' grid point axis =
  let rangeLimit = farthestNeighbor' grid point axis
      Point {row = row1, col = col1} = rangeLimit Axis.backward
      Point {row = rowN, col = colN} = rangeLimit Axis.forward
  in case axis of
       Axis.X -> Point row1 <$> [col1 .. colN]
       Axis.Y -> flip Point col1 <$> [row1 .. rowN]









