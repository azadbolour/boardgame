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
    Board
  , Board(dimension)
  , mkBoard
  , mkEmptyBoard
  , mkBoardFromPieces
  , rowsAsPieces
  , rowsAsStrings
  , colsAsPieces
  , next
  , prev
  , adjacent
  , get
  , getGridPieces
  , set
  , setN
  , isEmpty
  , stripOfPlay
  , inBounds
  , pointIsEmpty
  , pointIsNonEmpty
  , pointIsIsolatedInLine
  , nthNeighbor
  , validateCoordinate
  , validatePoint
--   , mkOKBoard
--   , mkBoardGridPoint
--   , checkGridPoint
--   , setBoardValue
--   , getValidGridPiece
--   , getGridPieces
--   , mkBoardFromPieces
--   , setBoardPieces
--   , centerGridPoint
--   , validPositionIsFree
--   , validPositionIsTaken
--   , pointHasNoLineNeighbors
--   , charRows
--   , getPiece
)
where

import Data.List
import qualified Data.Maybe as Maybe
import qualified Data.ByteString.Char8 as BS

import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Common.Domain.GridPiece (GridPiece)
import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.Point (Coordinate, Axis(..), Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import qualified BoardGame.Common.Domain.Point as Axis
import BoardGame.Common.Domain.SwissCheeseGrid (SwissCheeseGrid)
import qualified BoardGame.Common.Domain.SwissCheeseGrid as SwissCheeseGrid
import BoardGame.Server.Domain.GameError (GameError(..))
import qualified Bolour.Util.MiscUtil as Util
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip

-- | The game board.
data Board = Board {
    dimension :: Int
  , grid :: SwissCheeseGrid Piece
}
  deriving (Show)

-- TODO. Check rectangular. Check parameters. See below.
mkBoardFromPieces :: [[Maybe Piece]] -> Int -> Board
mkBoardFromPieces cells =
  let cellMaker row col = cells !! row !! col
  in mkBoard' cellMaker

-- TODO. Ditto.
mkBoard :: (Int -> Int -> Piece) -> Int -> Board
mkBoard pieceMaker =
  let cellMaker row col = Piece.toMaybe $ pieceMaker row col
  in mkBoard' cellMaker

mkEmptyBoard :: Int -> Board
mkEmptyBoard dimension =
  let grid = SwissCheeseGrid.mkEmptyGrid dimension dimension
  in Board dimension grid

mkBoard' :: (Int -> Int -> Maybe Piece) -> Int -> Board
mkBoard' cellMaker dimension =
  let grid = SwissCheeseGrid.mkGrid cellMaker dimension dimension
  in Board dimension grid

rowsAsPieces :: Board -> [[Piece]]
rowsAsPieces Board {grid} =
  let lineMapper row = (Piece.fromMaybe . fst) <$> row
  in lineMapper <$> SwissCheeseGrid.cells grid

colsAsPieces :: Board -> [[Piece]]
colsAsPieces Board {grid} =
  let lineMapper row = (Piece.fromMaybe . fst) <$> row
  in lineMapper <$> transpose (SwissCheeseGrid.cells grid)

next :: Board -> Point -> Axis -> Maybe Piece
next Board {grid} = SwissCheeseGrid.next grid

prev :: Board -> Point -> Axis -> Maybe Piece
prev Board {grid} = SwissCheeseGrid.prev grid

adjacent :: Board -> Point -> Axis -> Int -> Maybe Piece
adjacent Board {grid} = SwissCheeseGrid.adjacent grid

-- | Nothing if out of bounds, noPiece if empty but in bounds.
get :: Board -> Point -> Maybe Piece
get board @ Board { grid } point =
  if not (inBounds board point) then Nothing
  else
    let maybeVal = SwissCheeseGrid.get grid point
    in Just $ Piece.fromMaybe maybeVal

getGridPieces :: Board -> [GridPiece]
getGridPieces Board {grid} =
  let locatedPieces = SwissCheeseGrid.getJusts grid
      toGridPiece (piece, point) = GridValue piece point
  in toGridPiece <$> locatedPieces

set :: Board -> Point -> Piece -> Board
set Board { dimension, grid } point piece =
  let maybePiece = Piece.toMaybe piece
      grid' = SwissCheeseGrid.set grid point maybePiece
  in Board dimension grid'

setN :: Board -> [GridPiece] -> Board
setN board @ Board {dimension, grid} gridPoints =
  let toLocatedPoint GridValue {value = piece, point} = (Piece.toMaybe piece, point)
      locatedPoints = toLocatedPoint <$> gridPoints
      grid' = SwissCheeseGrid.setN grid locatedPoints
  in Board dimension grid'

isEmpty :: Board -> Bool
isEmpty Board { grid } =
  let cellList = concat $ SwissCheeseGrid.cells grid
  in all (Maybe.isNothing . fst) cellList

pointIsEmpty :: Board -> Point -> Bool
pointIsEmpty Board {grid} point =
  Maybe.isNothing $ SwissCheeseGrid.get grid point

pointIsNonEmpty :: Board -> Point -> Bool
pointIsNonEmpty board point = not $ pointIsEmpty board point

inBounds :: Board -> Point -> Bool
inBounds Board {grid} = SwissCheeseGrid.inBounds grid

validateCoordinate :: MonadError GameError m => Board -> Axis -> Coordinate -> m Coordinate
validateCoordinate (board @ Board { dimension }) axis coordinate =
  if coordinate >= 0 && coordinate < dimension then return coordinate
  else throwError $ PositionOutOfBoundsError axis (0, dimension) coordinate

validatePoint :: MonadError GameError m => Board -> Point -> m Point
validatePoint board (point @ Point { row, col }) = do
  _ <- validateCoordinate board Y row
  _ <- validateCoordinate board X col
  return point

rowsAsStrings :: Board -> [String]
rowsAsStrings board = ((\Piece {value} -> value) <$>) <$> rowsAsPieces board

pointIsIsolatedInLine :: Board -> Point -> Axis -> Bool
pointIsIsolatedInLine Board {grid} = SwissCheeseGrid.isolatedInLine grid

-- TODO. nthNeighbor belongs to Point

nthNeighbor :: Point -> Axis -> Int -> Int -> Point
nthNeighbor Point {row, col} axis direction steps =
  let offset = steps * direction
  in case axis of
       Axis.X -> Point row (col + offset)
       Axis.Y -> Point (row + offset) col

-- -- Assumes valid coordinates.
-- getValidGridPiece :: Board -> Point -> GridPiece
-- getValidGridPiece Board {grid} point = SwissCheeseGrid.cell grid point
--
-- centerGridPoint :: Board -> Point
-- centerGridPoint Board {dimension} = Point (dimension `div` 2) (dimension `div` 2)
--
-- -- gridPiecesToGrid :: Coordinate -> [GridPiece] -> SwissCheeseGrid GridPiece
-- -- gridPiecesToGrid dimension gridPieces =
-- --   let findGridPiece point = find ((== point) . GridValue.point) gridPieces
-- --       cellMaker r c = case findGridPiece $ Point r c of
-- --                         Nothing -> Piece.emptyPiece
-- --                         Just GridValue.GridValue {value} -> value
-- --   in SwissCheeseGrid.mkPointedGrid cellMaker dimension dimension
--
-- filterNonEmptyGridPieces :: [GridPiece] -> [GridPiece]
-- filterNonEmptyGridPieces = filter ((/= Piece.emptyPiece) . GridValue.value)
--
-- getGridPieces :: Board -> [GridPiece]
-- getGridPieces Board {grid} =
--   let SwissCheeseGrid {cells} = grid
--   in getGridPiecesOfCells cells
--
-- getGridPiecesOfCells :: [[GridPiece]] -> [GridPiece]
-- getGridPiecesOfCells cells = concat $ filterNonEmptyGridPieces <$> cells
--
-- -- mkBoardFromGridPieces :: Coordinate -> [GridPiece] -> Board
-- -- mkBoardFromGridPieces dimension gridPieces = Board dimension $ gridPiecesToGrid dimension gridPieces
--
-- mkBoardGridPoint :: Board -> Coordinate -> Coordinate -> Either GameError Point
-- mkBoardGridPoint board row col =
--    checkGridPoint board (Point row col)
--
-- mkBoard :: MonadError GameError m => Int -> m Board
-- mkBoard dimension
--   | Util.nonPositive dimension = throwInvalid dimension
--   | otherwise = return $ Board dimension (SwissCheeseGrid.mkPointedGrid (\row col -> Piece.emptyPiece) dimension dimension)
--       where throwInvalid size = throwError $ InvalidDimensionError size
--
-- mkOKBoard :: Coordinate -> Board
-- mkOKBoard dimension = Util.fromRight $ mkBoard dimension
--
--
-- pointHasNoLineNeighbors :: Board -> Point -> Axis -> Bool
-- pointHasNoLineNeighbors board point axis =
--   null $ lineNeighbors board point axis
--
-- lineNeighbors :: Board -> Point -> Axis -> [GridPiece]
--
-- lineNeighbors (Board {dimension, grid}) (Point {row, col}) X =
--   let cols = filter (\c -> c >= 0 && c < dimension) [col - 1, col + 1]
--       points = Point row <$> cols
--   in gridPiecesOfPoints grid points
--
-- lineNeighbors (Board {dimension, grid}) (Point {row, col}) Y =
--   let rows = filter (\r -> r >= 0 && r < dimension) [row - 1, row + 1]
--       points = flip Point col <$> rows
--   in gridPiecesOfPoints grid points
--
-- gridPiecesOfPoints :: SwissCheeseGrid GridPiece -> [Point] -> [GridPiece]
-- gridPiecesOfPoints SwissCheeseGrid {cells} points =
--   filter (\GridValue {point} -> elem point points) (getGridPiecesOfCells cells)
--
-- charRows :: Board -> [[Char]]
-- charRows Board {grid} = SwissCheeseGrid.cells $ GridPiece.gridLetter <$> grid
--

stripOfPlay :: Board -> [[Piece]] -> [PlayPiece] -> Maybe Strip
stripOfPlay board columns playPieces =
  if length playPieces < 2 then Nothing
  else Just $ stripOfPlay' board columns playPieces

stripOfPlay' :: Board -> [[Piece]] -> [PlayPiece] -> Strip
stripOfPlay' board cols playPieces =
  let points = (\PlayPiece {point} -> point) <$> playPieces
      hd @ Point {row = rowHead, col = colHead} = head points
      nxt @ Point {row = rowNext, col = colNext} = head $ tail points
      rows = rowsAsPieces board
      axis = if rowHead == rowNext then Axis.X else Axis.Y
      (lineNumber, line, begin) =
        case axis of
          Axis.X -> (rowHead, rows !! rowHead, colHead)
          Axis.Y -> (colHead, cols !! colHead, rowHead)
      -- end = begin + length points - 1
      lineAsString = Piece.piecesToString line
    in Strip.lineStrip axis lineNumber lineAsString begin (length points)
  -- in Strip.mkStrip axis lineNumber begin end content








