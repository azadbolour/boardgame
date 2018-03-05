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
  , height, width, rows, cols, numLines
  , get, getValues, set, setN
  , next, prev, adjacent
  , isBlack, isWhite, isEmpty, hasValue
  , inBounds
  , farthestNeighbor, lineNeighbors
  , segmentsInLine, segmentsAlongAxis, allSegments
  )
  where

import Data.List
import Data.Maybe (isJust, isNothing, fromJust, catMaybes)

import Bolour.Util.BlackWhite (BlackWhite(..))
import qualified Bolour.Util.BlackWhite as BlackWhite
import qualified Bolour.Util.Empty as Empty
import Bolour.Plane.Domain.Grid (Grid, Grid(Grid))
import qualified Bolour.Plane.Domain.Grid as Grid
import qualified Bolour.Plane.Domain.Axis as Axis
import qualified Bolour.Plane.Domain.Point as Point
import qualified Bolour.Plane.Domain.LineSegment as LineSegment
import Bolour.Plane.Domain.LineSegment (LineSegment, LineSegment(LineSegment))
import Bolour.Plane.Domain.Axis (Axis, Height, Width, Direction)
import Bolour.Plane.Domain.Point (Point, Point(Point))
import Bolour.Plane.Domain.BlackWhitePoint(BlackWhitePoint, BlackWhitePoint(BlackWhitePoint))
import qualified Bolour.Plane.Domain.BlackWhitePoint as BlackWhitePoint

data BlackWhiteGrid val = BlackWhiteGrid {
  innerGrid :: Grid (BlackWhitePoint val)
}

instance (Show val) => Show (BlackWhiteGrid val)
  where show grid = show $ rows grid

instance Empty.Empty (BlackWhiteGrid val)
  where isEmpty grid = all Empty.isEmpty (concat $ rows grid)

instance Empty.Empty (Maybe val, Point)
  where isEmpty x = let maybe = fst x in isNothing maybe

mkGrid :: (Height -> Width -> BlackWhite val) -> Height -> Width -> BlackWhiteGrid val
mkGrid cellMaker height width =
  let pointedCellMaker row col = BlackWhitePoint (cellMaker row col) (Point row col)
      inner = Grid.mkGrid pointedCellMaker height width
  in BlackWhiteGrid inner

mkEmptyGrid :: Height -> Width -> BlackWhiteGrid val
mkEmptyGrid = mkGrid (\height width -> White Nothing)

height :: BlackWhiteGrid val -> Height
height grid = Grid.height $ innerGrid grid

width :: BlackWhiteGrid val -> Width
width grid = Grid.width $ innerGrid grid

rows :: BlackWhiteGrid val -> [[BlackWhitePoint val]]
rows grid = Grid.rows $ innerGrid grid

cols :: BlackWhiteGrid val -> [[BlackWhitePoint val]]
cols grid = Grid.cols $ innerGrid grid

-- | Get the cell value of a point - if the point is out of bounds get Black.
get :: BlackWhiteGrid val -> Point -> BlackWhite val
get grid point =
  let maybeBlackWhitePoint = Grid.get (innerGrid grid) point
  in case maybeBlackWhitePoint of
     Nothing -> Black
     Just BlackWhitePoint {value} -> value

-- | Get the real values (White and 'Just') of the grid together with their locations.
getValues :: BlackWhiteGrid val -> [(val, Point)]
getValues grid = fromJustWhites (Grid.concatGrid $ innerGrid grid)

-- | Update the value of a point on the grid.
set :: BlackWhiteGrid val -> Point -> BlackWhite val -> BlackWhiteGrid val
set grid point value =
  let inner' = Grid.set (innerGrid grid) point (BlackWhitePoint value point)
  in BlackWhiteGrid inner'

setN :: BlackWhiteGrid val -> [BlackWhitePoint val] -> BlackWhiteGrid val
setN grid bwPoints =
  let inner' = Grid.setN (innerGrid grid) (addPoint <$> bwPoints)
        where addPoint bwPoint @ BlackWhitePoint {value, point} = (bwPoint, point)
  in BlackWhiteGrid inner'

-- | Get the value and location of the next point along an axis, if any.
--   Nothing means next is out of bounds.
next :: BlackWhiteGrid val -> Point -> Axis -> Maybe (BlackWhitePoint val)
next grid = Grid.next $ innerGrid grid

prev :: BlackWhiteGrid val -> Point -> Axis -> Maybe (BlackWhitePoint val)
prev grid = Grid.prev $ innerGrid grid

adjacent :: BlackWhiteGrid val -> Point -> Axis -> Direction -> Maybe (BlackWhitePoint val)
adjacent grid = Grid.adjacent $ innerGrid grid

isBlack :: BlackWhiteGrid val -> Point -> Bool
isBlack grid point = BlackWhite.isBlack $ get grid point

isWhite :: BlackWhiteGrid val -> Point -> Bool
isWhite grid point = BlackWhite.isWhite $ get grid point

isEmpty :: BlackWhiteGrid val -> Point -> Bool
isEmpty grid point = Empty.isEmpty $ get grid point

hasValue :: BlackWhiteGrid val -> Point -> Bool
hasValue grid point = BlackWhite.hasValue $ get grid point

inBounds :: BlackWhiteGrid val -> Point -> Bool
inBounds grid = Grid.inBounds $ innerGrid grid

-- | Get the farthest neighbor of a point along a given axis
--   in a given direction.
--
--   Given a point p on a line, a point q on that line
--   is considered to be a neighbor of p if there is a contiguous
--   non-empty white line segment between p and q (excluding p itself).
--   Axis X/Y horizontal/vertical. Direction Axis.forward or Axis.backward.
--   The point itself is considered a degenerate neighbour.
--   TODO. The point should not be a neighbor. Return Maybe.
farthestNeighbor :: BlackWhiteGrid val -> Point -> Axis -> Direction -> Point
farthestNeighbor grid point axis direction =
   if not (adjHasValue grid point axis direction) then point
   else fromJust $ find neighborIsValueBoundary neighbors
      where
        neighborIsValueBoundary neighbor = valueBoundary grid neighbor axis direction
        dimension = numLines grid axis
        neighbors = Point.nthNeighbor point axis direction <$> [1 .. dimension - 1]

-- | Get the number of lines of the grid parallel to a given axis:
--   X (number of horizontal lines: height), Y (number of vertical lines: width).
numLines :: BlackWhiteGrid val -> Axis -> Int
numLines grid = Grid.numLines $ innerGrid grid

-- | Get all the colinear neighbors in a given direction along a given axis
--   ordered in increasing value of the line index (excluding the point
--   itself). A colinear point is considered a neighbor if it has a real value,
--   and is adjacent to the given point, or recursively adjacent to a neighbor.
lineNeighbors :: BlackWhiteGrid val -> Point -> Axis -> Int -> [(val, Point)]
lineNeighbors grid point axis direction =
  let farthestPoint = farthestNeighbor grid point axis direction
      Point {row = pointRow, col = pointCol} = point
      Point {row = farRow, col = farCol} = farthestPoint
      range pos limit =
        -- Exclude the point itself.
        if direction == Axis.forward then [pos + 1 .. limit] else [limit .. pos - 1]
      neighbors =
        case axis of
          Axis.X -> Point pointRow <$> colRange
            where colRange = range pointCol farCol
          Axis.Y -> flip Point pointCol <$> rowRange
            where rowRange = range pointRow farRow
      blackWhitePoints = catMaybes $ Grid.get (innerGrid grid) <$> neighbors
  in fromJustWhites blackWhitePoints

fromJustWhites :: [BlackWhitePoint val] -> [(val, Point)]
fromJustWhites bwPoints =
  let maybePair BlackWhitePoint {value = bw, point} =
               let maybe = BlackWhite.fromWhite bw
               in case maybe of
                  Nothing -> Nothing
                  Just v -> Just (v, point)
  in catMaybes $ maybePair <$> bwPoints

adjValue :: BlackWhiteGrid val -> Point -> Axis -> Int -> Maybe val
adjValue grid point axis direction =
  do -- Maybe
    BlackWhitePoint {value} <- adjacent grid point axis direction
    BlackWhite.fromWhite value

adjHasValue :: BlackWhiteGrid val -> Point -> Axis -> Int -> Bool
adjHasValue grid point axis direction = isJust $ adjValue grid point axis direction

valueBoundary :: BlackWhiteGrid val -> Point -> Axis -> Int -> Bool
valueBoundary grid point axis direction =
  let adjacentHasValue = adjHasValue grid point axis direction
  in hasValue grid point && not (adjHasValue grid point axis direction)

linesAlongAxis :: BlackWhiteGrid val -> Axis -> [[BlackWhite val]]
linesAlongAxis grid axis =
  let Grid {rows = blackWhiteRows} = BlackWhitePoint.value <$> innerGrid grid
  in case axis of
       Axis.X -> blackWhiteRows
       Axis.Y -> transpose blackWhiteRows

segmentsAlongAxis :: BlackWhiteGrid val -> Axis -> [LineSegment val]
segmentsAlongAxis grid axis = do
  lineNumber <- [0 .. numLines grid axis - 1]
  segmentsInLine grid axis lineNumber

allSegments :: BlackWhiteGrid val -> [LineSegment val]
allSegments grid = segmentsAlongAxis grid Axis.X ++ segmentsAlongAxis grid Axis.Y

segmentsInLine :: BlackWhiteGrid val -> Axis -> Int -> [LineSegment val]
segmentsInLine grid axis lineNumber =
  let line = linesAlongAxis grid axis !! lineNumber
      len = length line
      black i = i < 0 || i >= len || BlackWhite.isBlack (line !! i)
      white i = not (black i)
      isBeginSegment i = white i && black (i - 1)
      isEndSegment i = white i && black (i + 1)
      range = [0 .. len - 1]
      begins = filter isBeginSegment range
      ends = filter isEndSegment range
      liveIntervals = zip begins ends
  in do
    (intervalBegin, intervalEnd) <- liveIntervals
    begin <- [intervalBegin .. intervalEnd]
    end <- [begin .. intervalEnd]
    let segment = BlackWhite.fromWhites line begin end
    return $ LineSegment axis lineNumber begin end segment





