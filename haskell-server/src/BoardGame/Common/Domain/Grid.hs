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

-- TODO. Move to package Bolour.General.Domain. TODO. What is the naming convention for this type of thing?
-- Point and GridValue would also move to a more generic place.

{-|
Definition of the game grid and its dependencies.
-}
module BoardGame.Common.Domain.Grid (
    Grid(..)
  , mkGrid
  , mkPointedGrid
  , setGridValue
  , setGridValues
  , getValue
  , cell
  , nextValue
  , prevValue
  , mapMatrixWithCoordinates
  , kStrips
  , stripsByLength
  , matrixStrips
  , matrixStripsByLength
  , setPointedGridValues
  , filterGrid
  , concatGrid
  , concatFilter
) where

import Data.List

import qualified Bolour.Util.MiscUtil as Util

import BoardGame.Common.Domain.Point (Point, Point(Point), Axis, Coordinate, Height, Width)
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue

-- |The 2-dimensional grid of squares on a game board.
data Grid val = Grid {
  cells :: [[val]]
} deriving (Functor)

deriving instance (Show val) => Show (Grid val)

-- TODO. Grid must be rectangular. Check all rows same length at least 1, and at least 1 row.
mkGrid :: (Coordinate -> Width -> val) -> Height -> Width -> Grid val
mkGrid cellMaker height width = Grid $ (\r -> mkRow (cellMaker r) width) <$> [0 .. height - 1]

mkRow :: (Width -> val) -> Width -> [val]
mkRow cellMaker width = cellMaker <$> [0 .. width - 1]

mkPointedGrid :: (Height -> Width -> val) -> Height -> Width -> Grid (GridValue val)
mkPointedGrid cellMaker = mkGrid (\row col -> GridValue (cellMaker row col) (Point row col))

filterGrid :: (val -> Bool) -> Grid val -> Grid val
filterGrid predicate Grid{cells} = Grid $ filter predicate <$> cells

concatGrid :: Grid val -> [val]
concatGrid Grid{cells} = concat cells

concatFilter :: (val -> Bool) -> Grid val -> [val]
concatFilter predicate grid = concatGrid $ filterGrid predicate grid

-- | Update the value of a cell on the grid.
setGridValue ::
     Grid val     -- ^ The grid.
  -> Point        -- ^ The coordinates of the cell being updated.
  -> val          -- ^ The new value of the grid cell.
  -> Grid val     -- ^ The updated grid.

setGridValue grid Point { row, col } value =
  let contents = cells grid
      updated = Util.setListElement contents row (Util.setListElement (contents !! row) col value)
  in Grid updated

setGridValues :: Grid val -> [GridValue val] -> Grid val
setGridValues = foldl' (\grid GridValue {value, point} -> setGridValue grid point value)

setPointedGridValues :: Grid (GridValue val) -> [GridValue val] -> Grid (GridValue val)
setPointedGridValues =
  foldl' (\grid gridVal -> setGridValue grid (GridValue.point gridVal) gridVal)

-- | Get a cell on the grid.
getValue :: Grid val -> Coordinate -> Coordinate -> val
getValue Grid {cells} row col = cells !! row !! col

cell :: Grid val -> Point -> val
cell grid (Point {row, col}) = getValue grid row col

-- | Get the next cell adjacent to a given cell on the grid.
nextValue ::
     Grid val           -- ^ The grid.
  -> Point              -- ^ The position of the anchor.
  -> Axis               -- ^ Horizontal or vertical next.
  -> Point.Coordinate   -- ^ Size of the line along which to get next cell.
  -> Maybe val          -- ^ Next cell if there is one - Nothing if along the edge or out of bounds.

nextValue grid (Point {row, col}) Axis.X width =
  if col >= width - 1 || col < 0
    then Nothing
    else Just $ getValue grid row (col + 1)

nextValue grid (Point {row, col}) Axis.Y height =
  if row >= height - 1 || row < 0
    then Nothing
    else Just $ getValue grid (row + 1) col

-- | Get the previous cell adjacent to a given cell on the grid.
--   See nextCell.
prevValue :: Grid val -> Point -> Axis -> Point.Coordinate -> Maybe val

prevValue grid (Point {row, col}) Axis.X width =
  if col >= width || col <= 0
    then Nothing
    else Just $ getValue grid row (col - 1)

prevValue grid (Point {row, col}) Axis.Y height =
  if row >= height || row <= 0
    then Nothing
    else Just $ getValue grid (row - 1) col

-- | Map a function of coordinates and cells onto a matrix.
mapMatrixWithCoordinates :: [[a]] -> (Coordinate -> Coordinate -> a -> b) -> [[b]]
mapMatrixWithCoordinates matrix mapper =
  zipWith rowAdder [0 .. length matrix - 1] matrix
  where rowAdder rowNum line = zipWith (mapper rowNum) [0 .. length line - 1] line

-- | Get contiguous sub-lists (strips) of a given length k.
kStrips :: [a] -> Int -> [[a]]
kStrips list size = (\i -> (take size . drop i) list) <$> [0 .. length list - size]

-- V.generate (V.length vector - size + 1) (\pos -> V.slice pos size vector)

-- | Get sets of strips of a vector indexed by length.
--   Zero is included as a length, so that the resulting vector
--   can be indexed simply by length.
stripsByLength :: [a] -> [[[a]]]
stripsByLength list = kStrips list <$> [0 .. length list]

-- | Get all strips of a matrix - indexed by row, then by strip length.
--   The indexing dimensions are: row, length, col, position in strip.
matrixStrips :: [[a]] -> [[[[a]]]]
matrixStrips matrix = stripsByLength <$> matrix

-- | Get all the strips of a matrix indexed by length.
--   The indexing dimensions are length, strip-number, position in strip.
matrixStripsByLength :: [[a]] -> [[[a]]]
matrixStripsByLength matrix =
  foldl1' pairwiseConcat (matrixStrips matrix)
  where pairwiseConcat = zipWith (++)