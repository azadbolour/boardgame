--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.Board (
    Board(..)
  , mkBoard
  , mkOKBoard
  , mkBoardGridPoint
  , checkGridPoint
  , setBoardValue
  , getValidGridPiece
  , getGridPieces
  , mkBoardFromGridPieces
  , setBoardPieces
  , centerGridPoint
  , validPositionIsFree
  , validPositionIsTaken
  , pointHasNoLineNeighbors
  , charRows
  , isEmpty
)
where

import Data.List
import qualified Data.ByteString.Char8 as BS

import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Common.Domain.GridPiece (GridPiece)
import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.Point (Coordinate, Height, Width, Axis(..), Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Server.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Server.Domain.Grid as Grid
import BoardGame.Server.Domain.GameError (GameError(..))
import qualified Bolour.Util.MiscUtil as Util

-- | The game board.
data Board = Board {
    dimension :: Coordinate
  , grid :: Grid GridPiece
}
  deriving (Show)

isEmpty :: Board -> Bool
isEmpty Board{grid} = null $ Grid.concatFilter (\GridValue{value} -> Piece.isPiece value) grid

-- Assumes valid coordinates.
getValidGridPiece :: Board -> Point -> GridPiece
getValidGridPiece Board {grid} Point {row, col} = Grid.getValue grid row col

centerGridPoint :: Board -> Point
centerGridPoint Board {dimension} = Point (dimension `div` 2) (dimension `div` 2)

gridPiecesToGrid :: Coordinate -> [GridPiece] -> Grid GridPiece
gridPiecesToGrid dimension gridPieces =
  let findGridPiece point = find ((== point) . GridValue.point) gridPieces
      cellMaker r c = case findGridPiece $ Point r c of
                        Nothing -> Piece.noPiece
                        Just GridValue.GridValue {value} -> value
  in Grid.mkPointedGrid cellMaker dimension dimension

filterNonEmptyGridPieces :: [GridPiece] -> [GridPiece]
filterNonEmptyGridPieces = filter ((/= Piece.noPiece) . GridValue.value)

getGridPieces :: Board -> [GridPiece]
getGridPieces Board {grid} =
  let Grid {cells} = grid
  in getGridPiecesOfCells cells

getGridPiecesOfCells :: [[GridPiece]] -> [GridPiece]
getGridPiecesOfCells cells = concat $ filterNonEmptyGridPieces <$> cells

mkBoardFromGridPieces :: Coordinate -> [GridPiece] -> Board
mkBoardFromGridPieces dimension gridPieces = Board dimension $ gridPiecesToGrid dimension gridPieces

mkBoardGridPoint :: Board -> Coordinate -> Coordinate -> Either GameError Point
mkBoardGridPoint board row col =
   checkGridPoint board (Point row col)

mkOutOfBounds :: Board -> Axis -> Coordinate -> GameError
mkOutOfBounds (board @ Board { dimension }) axis pos =
  PositionOutOfBoundsError axis (0, dimension) pos

mkBoard :: MonadError GameError m => Int -> m Board
mkBoard dimension
  | Util.nonPositive dimension = throwInvalid dimension
  | otherwise = return $ Board dimension (Grid.mkPointedGrid (\row col -> Piece.noPiece) dimension dimension)
      where throwInvalid size = throwError $ InvalidDimensionError size

mkOKBoard :: Coordinate -> Board
mkOKBoard dimension = Util.fromRight $ mkBoard dimension

validPositionIsFree :: Board -> Point -> Bool
validPositionIsFree board validPos =
  let GridValue {value, point} = getValidGridPiece board validPos
  in value == Piece.noPiece

validPositionIsTaken :: Board -> Point -> Bool
validPositionIsTaken board point = not $ validPositionIsFree board point
-- TODO. Is there a point-free shorthand for this type of composition.

checkAxisPosition :: MonadError GameError m => Board -> Axis -> Coordinate -> m Coordinate
checkAxisPosition (board @ Board { dimension }) axis position =
  if position < 0 || position >= dimension then
    throwError $ mkOutOfBounds board axis position
  else
    return position

checkGridPoint :: MonadError GameError m => Board -> Point -> m Point
checkGridPoint board (point @ Point { row, col }) = do
  _ <- checkAxisPosition board Y row
  _ <- checkAxisPosition board X col
  return point

setBoardValue :: Board -> Point -> Piece -> Board
setBoardValue board point piece =
  board { grid = Grid.setGridValue (grid board) point (GridValue piece point) }

setBoardPieces :: Board -> [GridPiece] -> Board
setBoardPieces board gridPieces =
  board { grid = Grid.setPointedGridValues (grid board) gridPieces }

pointHasNoLineNeighbors :: Board -> Point -> Axis -> Bool
pointHasNoLineNeighbors board point axis =
  null $ lineNeighbors board point axis

lineNeighbors :: Board -> Point -> Axis -> [GridPiece]

lineNeighbors (Board {dimension, grid}) (Point {row, col}) X =
  let cols = filter (\c -> c >= 0 && c < dimension) [col - 1, col + 1]
      points = Point row <$> cols
  in gridPiecesOfPoints grid points

lineNeighbors (Board {dimension, grid}) (Point {row, col}) Y =
  let rows = filter (\r -> r >= 0 && r < dimension) [row - 1, row + 1]
      points = flip Point col <$> rows
  in gridPiecesOfPoints grid points

gridPiecesOfPoints :: Grid GridPiece -> [Point] -> [GridPiece]
gridPiecesOfPoints Grid {cells} points =
  filter (\GridValue {point} -> elem point points) (getGridPiecesOfCells cells)

charRows :: Board -> [[Char]]
charRows Board {grid} = Grid.cells $ GridPiece.gridLetter <$> grid






