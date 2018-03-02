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

{-|
Definition of the game grid and its dependencies.
-}
module Bolour.Plane.Domain.Grid (
    Grid(..)
  , mkGrid
  , get
  , cell
  , set
  , setN
  , next
  , prev
  , inBounds
  , filterGrid
  , concatGrid
  , concatFilter
  , adjacentCell
  , numLines
) where

import Data.List (foldl', transpose)
import Data.Maybe (fromJust)

import qualified Bolour.Util.MiscUtil as Util

import Bolour.Plane.Domain.Point (Point, Point(Point), Axis, Coordinate, Height, Width)
import qualified Bolour.Plane.Domain.Point as Axis
import qualified Bolour.Plane.Domain.Point as Point

-- |The 2-dimensional grid of squares on a game board.
data Grid val = Grid {
    height :: Height
  , width :: Width
  , rows :: [[val]]
  , cols :: [[val]]
} deriving (Functor)

deriving instance (Show val) => Show (Grid val)

-- TODO. Check parameters.
mkGrid :: (Height -> Width -> val) -> Height -> Width -> Grid val
mkGrid cellMaker height width =
  let rowMaker row = mkRow (cellMaker row) width
      rows = rowMaker <$> [0 .. height - 1]
  in mkGridFromRows rows height width

mkGridFromRows :: [[val]] -> Height -> Width -> Grid val
mkGridFromRows rows height width =
  let cols = transpose rows
  in Grid height width rows cols

mkRow :: (Width -> val) -> Width -> [val]
mkRow cellMaker width = cellMaker <$> [0 .. width - 1]

-- mkPointedGrid :: (Height -> Width -> val) -> Height -> Width -> Grid (GridValue val)
-- mkPointedGrid cellMaker =
--   let pointedCellMaker row col = GridValue (cellMaker row col) (Point row col)
--   in mkGrid pointedCellMaker

-- | Get a cell on the grid.
get :: Grid val -> Point -> Maybe val
get grid @ Grid {rows} (point @ Point {row, col}) =
  if not (inBounds grid point) then Nothing
  else Just $ rows !! row !! col

get' :: Grid val -> Height -> Width -> Maybe val
get' grid @ Grid {rows} row col = get grid $ Point row col

-- | Update the value of a cell on the grid.
set ::
     Grid val     -- ^ The grid.
  -> Point        -- ^ The coordinates of the cell being updated.
  -> val          -- ^ The new value of the grid cell.
  -> Grid val     -- ^ The updated grid.

set Grid {height, width, rows} Point { row, col } value =
  let rows' = Util.setListElement rows row (Util.setListElement (rows !! row) col value)
  in mkGridFromRows rows' height width

setN :: Grid val -> [(val, Point)] -> Grid val
setN = foldl' (\grid (value, point) -> set grid point value)

-- setPointedGridValues :: Grid (GridValue val) -> [GridValue val] -> Grid (GridValue val)
-- setPointedGridValues =
--   foldl' (\grid gridVal -> set grid (GridValue.point gridVal) gridVal)

cell :: Grid val -> Point -> val
cell grid = fromJust . get grid

inBounds :: Grid val -> Point -> Bool
inBounds Grid {height, width} Point {row, col} =
  row >= 0 && row < height && col >= 0 && col < width

-- | Get the next cell adjacent to a given cell on the grid.
next ::
     Grid val           -- ^ The grid.
  -> Point              -- ^ The position of the anchor.
  -> Axis               -- ^ Horizontal or vertical next.
  -> Maybe val          -- ^ Next cell if there is one - Nothing if along the edge or out of bounds.

next (grid @ Grid {height, width}) (point @ (Point {row, col})) Axis.X =
  if not (inBounds grid point) || col == width - 1
    then Nothing
    else get' grid row (col + 1)

next (grid @ Grid {height, width}) (point @ (Point {row, col})) Axis.Y =
  if not (inBounds grid point) || row == height - 1
    then Nothing
    else get' grid (row + 1) col

-- | Get the previous cell adjacent to a given cell on the grid.
--   See nextCell.
prev :: Grid val -> Point -> Axis -> Maybe val

prev (grid @ Grid {height, width}) (point @ (Point {row, col})) Axis.X =
  if not (inBounds grid point) || col == 0
    then Nothing
    else get' grid row (col - 1)

prev (grid @ Grid {height, width}) (point @ (Point {row, col})) Axis.Y =
  if not (inBounds grid point) || row == 0
    then Nothing
    else get' grid (row - 1) col

adjacentCell :: Grid val -> Point -> Axis -> Int -> Maybe val
adjacentCell grid point axis direction =
  let calcAdj = if direction == 1 then next else prev
  in calcAdj grid point axis

filterGrid :: (val -> Bool) -> Grid val -> Grid val
filterGrid predicate grid @ Grid{rows} = grid { rows = filter predicate <$> rows }

concatGrid :: Grid val -> [val]
concatGrid Grid{rows} = concat rows

concatFilter :: (val -> Bool) -> Grid val -> [val]
concatFilter predicate grid = concatGrid $ filterGrid predicate grid

numLines :: Grid val -> Axis -> Int
numLines grid Axis.X = height grid
numLines grid Axis.Y = width grid
