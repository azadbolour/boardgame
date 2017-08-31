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
)
where

import Data.List
import qualified Data.Map as Map
import qualified Data.Set as Set
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
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip), GroupedStrips)
import qualified BoardGame.Server.Domain.Strip as Strip
import BoardGame.Server.Domain.GameError (GameError(..))
import qualified Bolour.Util.MiscUtil as Util

-- | The game board.
data Board = Board {
    height :: Height
  , width :: Width
  , grid :: Grid GridPiece
}
  deriving (Show)

-- Assumes valid coordinates.
getValidGridPiece :: Board -> Point -> GridPiece
getValidGridPiece Board {grid} Point {row, col} = Grid.getValue grid row col

centerGridPoint :: Board -> Point
centerGridPoint Board {height, width} = Point (height `div` 2) (width `div` 2)

gridPiecesToGrid :: Height -> Width -> [GridPiece] -> Grid GridPiece
gridPiecesToGrid height width gridPieces =
  let findGridPiece point = find ((== point) . GridValue.point) gridPieces
      cellMaker r c = case findGridPiece $ Point r c of
                        Nothing -> Piece.noPiece
                        Just GridValue.GridValue {value} -> value
  in Grid.mkPointedGrid cellMaker height width

filterNonEmptyGridPieces :: [GridPiece] -> [GridPiece]
filterNonEmptyGridPieces = filter ((/= Piece.noPiece) . GridValue.value)

getGridPieces :: Board -> [GridPiece]
getGridPieces Board {height, width, grid} =
  let Grid {cells} = grid
  in getGridPiecesOfCells cells
  -- in concat $ filterNonEmptyGridPieces <$> cells

getGridPiecesOfCells :: [[GridPiece]] -> [GridPiece]
getGridPiecesOfCells cells = concat $ filterNonEmptyGridPieces <$> cells

mkBoardFromGridPieces :: Height -> Width -> [GridPiece] -> Board
mkBoardFromGridPieces height width gridPieces = Board height width $ gridPiecesToGrid height width gridPieces

mkBoardGridPoint :: Board -> Height -> Width -> Either GameError Point
mkBoardGridPoint board row col =
   checkGridPoint board (Point row col)

mkOutOfBounds :: Board -> Axis -> Coordinate -> GameError
mkOutOfBounds board axis =
  PositionOutOfBoundsError axis (0, boardDimension board axis - 1)

mkBoard :: MonadError GameError m => Height -> Width -> m Board
mkBoard height width
  | Util.nonPositive height = throwInvalid Y height
  | Util.nonPositive width = throwInvalid X width
  | otherwise = return $ Board height width (Grid.mkPointedGrid (\row col -> Piece.noPiece) height width)
      where throwInvalid axis size = throwError $ InvalidDimensionError axis size

mkOKBoard :: Height -> Width -> Board
mkOKBoard height width = Util.fromRight $ mkBoard height width

validPositionIsFree :: Board -> Point -> Bool
validPositionIsFree board validPos =
  let GridValue {value, point} = getValidGridPiece board validPos
  in value == Piece.noPiece

validPositionIsTaken :: Board -> Point -> Bool
validPositionIsTaken board point = not $ validPositionIsFree board point
-- TODO. Is there a point-free shorthand for this type of composition.

boardDimension :: Board -> Axis -> Coordinate
boardDimension board axis = case axis of
  X -> width board
  Y -> height board

checkAxisPosition :: MonadError GameError m => Board -> Axis -> Coordinate -> m Coordinate
checkAxisPosition board axis position =
  if position < 0 || position >= boardDimension board axis then
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

lineNeighbors (Board {height, width, grid}) (Point {row, col}) X =
  let cols = filter (\c -> c >= 0 && c < width) [col - 1, col + 1]
      points = Point row <$> cols
  in gridPiecesOfPoints grid points

lineNeighbors (Board {height, width, grid}) (Point {row, col}) Y =
  let rows = filter (\r -> r >= 0 && r < height) [row - 1, row + 1]
      points = flip Point col <$> rows
  in gridPiecesOfPoints grid points

gridPiecesOfPoints :: Grid GridPiece -> [Point] -> [GridPiece]
gridPiecesOfPoints Grid {cells} points =
  filter (\GridValue {point} -> elem point points) (getGridPiecesOfCells cells)

charRows :: Board -> [[Char]]
charRows Board {grid} = Grid.cells $ GridPiece.gridLetter <$> grid

-- -- | A strip is playable iff it has at least 1 anchor letter,
-- --   and at most c blanks, where c is the capacity of the tray.
-- computePlayableStrips :: Board -> Int -> GroupedStrips
--
-- TODO. Board should just have a dimension.
--
-- computePlayableStrips (board @ Board {width = dimension}) trayCapacity =
--   let allStrips = let rows = charRows board
--                   in Strip.allStripsByLengthByBlanks rows dimension
--       blanksFilter blanks strips = blanks > 0 && blanks <= trayCapacity
--       filterPlayableBlanks stripsByBlanks = blanksFilter `Map.filterWithKey` stripsByBlanks
--       playableStrips = filterPlayableBlanks <$> allStrips
--       hasAnchor strip @ Strip { letters } = BS.length letters > 0
--       filterStripsForAnchor = filter hasAnchor -- :: [Strip] -> [Strip]
--       filterStripsByBlankForAnchor = (filterStripsForAnchor <$>) -- :: Map BlankCount [Strip] -> Map BlankCount [Strip]
--       playableStrips' = filterStripsByBlankForAnchor <$> playableStrips
--   in playableStrips'







