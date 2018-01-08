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
  , mkPointedGrid
  , setPointedGridValues
) where

import Data.List
import Data.Maybe (fromJust)

import qualified Bolour.Util.MiscUtil as Util

import BoardGame.Common.Domain.Point (Point, Point(Point), Axis, Coordinate, Height, Width)
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue

-- |The 2-dimensional grid of squares on a game board.
data Grid val = Grid {
    height :: Height
  , width :: Width
  , cells :: [[val]]
} deriving (Functor)

deriving instance (Show val) => Show (Grid val)

-- TODO. Check parameters.
mkGrid :: (Height -> Width -> val) -> Height -> Width -> Grid val
mkGrid cellMaker height width =
  let rowMaker row = mkRow (cellMaker row) width
      rows = rowMaker <$> [0 .. height - 1]
  in Grid height width rows

mkRow :: (Width -> val) -> Width -> [val]
mkRow cellMaker width = cellMaker <$> [0 .. width - 1]

mkPointedGrid :: (Height -> Width -> val) -> Height -> Width -> Grid (GridValue val)
mkPointedGrid cellMaker =
  let pointedCellMaker row col = GridValue (cellMaker row col) (Point row col)
  in mkGrid pointedCellMaker

-- | Get a cell on the grid.
get :: Grid val -> Point -> Maybe val
get grid @ Grid {cells} (point @ Point {row, col}) =
  if not (inBounds grid point) then Nothing
  else Just $ cells !! row !! col

get' :: Grid val -> Height -> Width -> Maybe val
get' grid @ Grid {cells} row col = get grid $ Point row col

-- | Update the value of a cell on the grid.
set ::
     Grid val     -- ^ The grid.
  -> Point        -- ^ The coordinates of the cell being updated.
  -> val          -- ^ The new value of the grid cell.
  -> Grid val     -- ^ The updated grid.

set grid Point { row, col } value =
  let contents = cells grid
      updated = Util.setListElement contents row (Util.setListElement (contents !! row) col value)
  in grid { cells = updated }

setN :: Grid val -> [GridValue val] -> Grid val
setN = foldl' (\grid GridValue {value, point} -> set grid point value)

setPointedGridValues :: Grid (GridValue val) -> [GridValue val] -> Grid (GridValue val)
setPointedGridValues =
  foldl' (\grid gridVal -> set grid (GridValue.point gridVal) gridVal)

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

adjacentCell :: Grid val -> Point -> Axis -> Int -> Int -> Maybe val
adjacentCell grid point axis direction limit =
  let calcAdj = if direction == 1 then next else prev
  in calcAdj grid point axis

filterGrid :: (val -> Bool) -> Grid val -> Grid val
filterGrid predicate grid @ Grid{cells} = grid { cells = filter predicate <$> cells }

concatGrid :: Grid val -> [val]
concatGrid Grid{cells} = concat cells

concatFilter :: (val -> Bool) -> Grid val -> [val]
concatFilter predicate grid = concatGrid $ filterGrid predicate grid



-- TODO. If needed, move the functions below to separate list utility class.
-- They could be useful in cleaning up strip code.
-- | Map a function of coordinates and cells onto a matrix.
-- mapMatrixWithCoordinates :: [[a]] -> (Coordinate -> Coordinate -> a -> b) -> [[b]]
-- mapMatrixWithCoordinates matrix mapper =
--   zipWith rowAdder [0 .. length matrix - 1] matrix
--   where rowAdder rowNum line = zipWith (mapper rowNum) [0 .. length line - 1] line

-- | Get contiguous sub-lists (strips) of a given length k.
-- kStrips :: [a] -> Int -> [[a]]
-- kStrips list size = (\i -> (take size . drop i) list) <$> [0 .. length list - size]

-- V.generate (V.length vector - size + 1) (\pos -> V.slice pos size vector)

-- | Get sets of strips of a vector indexed by length.
--   Zero is included as a length, so that the resulting vector
--   can be indexed simply by length.
-- stripsByLength :: [a] -> [[[a]]]
-- stripsByLength list = kStrips list <$> [0 .. length list]

-- | Get all strips of a matrix - indexed by row, then by strip length.
--   The indexing dimensions are: row, length, col, position in strip.
-- matrixStrips :: [[a]] -> [[[[a]]]]
-- matrixStrips matrix = stripsByLength <$> matrix

-- | Get all the strips of a matrix indexed by length.
--   The indexing dimensions are length, strip-number, position in strip.
-- matrixStripsByLength :: [[a]] -> [[[a]]]
-- matrixStripsByLength matrix =
--   foldl1' pairwiseConcat (matrixStrips matrix)
--   where pairwiseConcat = zipWith (++)
