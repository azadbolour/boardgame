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
  , validateCoordinate
  , validatePoint
  , farthestNeighbor
  , surroundingRange
  , getLetter
  , groupedStrips
)
where

import Data.List
import qualified Data.Maybe as Maybe
import Data.Map (Map)
import qualified Data.Map as Map

-- import qualified Data.ByteString.Char8 as BS

import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import Bolour.Grid.GridValue (GridValue(GridValue))
import BoardGame.Common.Domain.GridPiece (GridPiece)
import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import qualified Bolour.Grid.GridValue as GridValue
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import Bolour.Grid.Point (Coordinate, Axis(..), Point, Point(Point))
import qualified Bolour.Grid.Point as Point
import qualified Bolour.Grid.Point as Axis
import Bolour.Grid.SparseGrid (SparseGrid)
import qualified Bolour.Grid.SparseGrid as SparseGrid
import BoardGame.Server.Domain.GameError (GameError(..))
import qualified Bolour.Util.MiscUtil as Util
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip

-- | The game board.
data Board = Board {
    dimension :: Int
  , grid :: SparseGrid Piece
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
  let grid = SparseGrid.mkEmptyGrid dimension dimension
  in Board dimension grid

mkBoard' :: (Int -> Int -> Maybe Piece) -> Int -> Board
mkBoard' cellMaker dimension =
  let grid = SparseGrid.mkGrid cellMaker dimension dimension
  in Board dimension grid

rowsAsPieces :: Board -> [[Piece]]
rowsAsPieces Board {grid} =
  let lineMapper row = (Piece.fromMaybe . fst) <$> row
  in lineMapper <$> SparseGrid.cells grid

colsAsPieces :: Board -> [[Piece]]
colsAsPieces Board {grid} =
  let lineMapper row = (Piece.fromMaybe . fst) <$> row
  in lineMapper <$> transpose (SparseGrid.cells grid)

next :: Board -> Point -> Axis -> Maybe Piece
next Board {grid} point axis = do
  (maybePiece, _) <- SparseGrid.next grid point axis
  maybePiece

prev :: Board -> Point -> Axis -> Maybe Piece
prev Board {grid} point axis = do
  (maybePiece, _) <- SparseGrid.prev grid point axis
  maybePiece

adjacent :: Board -> Point -> Axis -> Int -> Maybe Piece
adjacent Board {grid} point axis direction = do
  (maybePiece, _) <- SparseGrid.adjacent grid point axis direction
  maybePiece

-- | Nothing if out of bounds, noPiece if empty but in bounds.
get :: Board -> Point -> Maybe Piece
get board @ Board { grid } point =
  if not (inBounds board point) then Nothing
  else
    let maybeVal = SparseGrid.get grid point
    in Just $ Piece.fromMaybe maybeVal

-- | Assume point is valid.
getLetter :: Board -> Point -> Char
getLetter board point =
  Piece.value $ Maybe.fromJust $ get board point

getGridPieces :: Board -> [GridPiece]
getGridPieces Board {grid} =
  let locatedPieces = SparseGrid.getJusts grid
      toGridPiece (piece, point) = GridValue piece point
  in toGridPiece <$> locatedPieces

set :: Board -> Point -> Piece -> Board
set Board { dimension, grid } point piece =
  let maybePiece = Piece.toMaybe piece
      grid' = SparseGrid.set grid point maybePiece
  in Board dimension grid'

setN :: Board -> [GridPiece] -> Board
setN board @ Board {dimension, grid} gridPoints =
  let toLocatedPoint GridValue {value = piece, point} =
        (Piece.toMaybe piece, point)
      locatedPoints = toLocatedPoint <$> gridPoints
      grid' = SparseGrid.setN grid locatedPoints
  in Board dimension grid'

isEmpty :: Board -> Bool
isEmpty Board { grid } =
  let cellList = concat $ SparseGrid.cells grid
  in all (Maybe.isNothing . fst) cellList

pointIsEmpty :: Board -> Point -> Bool
pointIsEmpty Board {grid} point =
  Maybe.isNothing $ SparseGrid.get grid point

pointIsNonEmpty :: Board -> Point -> Bool
pointIsNonEmpty board point = not $ pointIsEmpty board point

inBounds :: Board -> Point -> Bool
inBounds Board {grid} = SparseGrid.inBounds grid

validateCoordinate :: MonadError GameError m =>
  Board -> Axis -> Coordinate -> m Coordinate

validateCoordinate (board @ Board { dimension }) axis coordinate =
  if coordinate >= 0 && coordinate < dimension then return coordinate
  else throwError $ PositionOutOfBoundsError axis (0, dimension) coordinate

validatePoint :: MonadError GameError m =>
  Board -> Point -> m Point

validatePoint board (point @ Point { row, col }) = do
  _ <- validateCoordinate board Y row
  _ <- validateCoordinate board X col
  return point

rowsAsStrings :: Board -> [String]
rowsAsStrings board = ((\Piece {value} -> value) <$>) <$> rowsAsPieces board

pointIsIsolatedInLine :: Board -> Point -> Axis -> Bool
pointIsIsolatedInLine Board {grid} = SparseGrid.isolatedInLine grid

farthestNeighbor :: Board -> Point -> Axis -> Int -> Point
farthestNeighbor Board {grid} = SparseGrid.farthestNeighbor grid

stripOfPlay :: Board -> [[Piece]] -> [PlayPiece] -> Maybe Strip
stripOfPlay board columns playPieces =
  if length playPieces < 2 then Nothing
  else stripOfPlay' board columns playPieces

stripOfPlay' :: Board -> [[Piece]] -> [PlayPiece] -> Maybe Strip
stripOfPlay' board cols playPieces =
  let rows = rowsAsPieces board
      points = (\PlayPiece {point} -> point) <$> playPieces
      Point {row = hdRow, col = hdCol} = head points
      maybeAxis = Point.axisOfLine points
  in
    let mkStrip axis =
          let (lineNumber, line, begin) =
                case axis of
                  Axis.X -> (hdRow, rows !! hdRow, hdCol)
                  Axis.Y -> (hdCol, cols !! hdCol, hdRow)
              lineAsString = Piece.piecesToString line
           in Strip.lineStrip axis lineNumber lineAsString begin (length points)
    in mkStrip <$> maybeAxis

surroundingRange :: Board -> Point -> Axis -> [Point]
surroundingRange Board {grid} = SparseGrid.surroundingRange grid

-- TODO. Import type GroupedStrips.

groupedStrips :: Board -> Map Int (Map Int [Strip])
groupedStrips Board {grid} = Strip.groupedStrips grid



