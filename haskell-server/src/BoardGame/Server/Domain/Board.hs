--
-- Copyright 2017-2018 Azad Bolour
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
  , mkBoard, mkEmptyBoard, mkBoardFromPieces, mkBoardFromPiecePoints
  , rows, cols
  , next, prev, adjacent
  , get, getPiece, getGridPieces
  , setN, setBlackPoints, setPiecePoints
  , isEmpty, isFilled, inBounds
  , stripOfPlay, stripOfBoard
  , pointIsEmpty, pointIsNonEmpty
  , pointHasValue, pointHasRealNeighbor
  , validateCoordinate, validatePoint
  , stripIsDisconnectedInLine
  , playableEnclosingStripsOfBlankPoints
  , lineNeighbors
  , computeAllLiveStrips, playableStrips
)
where

import Data.List
import qualified Data.Map as Map
import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.PiecePoint (PiecePoint, PiecePoint(PiecePoint))
import qualified BoardGame.Common.Domain.PiecePoint as PiecePoint
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import Bolour.Plane.Domain.Axis (Coordinate, Axis(..))
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
import Bolour.Plane.Domain.LineSegment (LineSegment, LineSegment(LineSegment))
import qualified Bolour.Plane.Domain.LineSegment as LineSegment
import qualified Bolour.Plane.Domain.Axis as Axis
import Bolour.Util.BlackWhite (BlackWhite, BlackWhite(Black, White))
import qualified Bolour.Util.BlackWhite as BlackWhite
import Bolour.Plane.Domain.BlackWhitePoint (BlackWhitePoint, BlackWhitePoint(BlackWhitePoint))
import qualified Bolour.Plane.Domain.BlackWhitePoint as BlackWhitePoint
import Bolour.Plane.Domain.BlackWhiteGrid (BlackWhiteGrid)
import qualified Bolour.Plane.Domain.BlackWhiteGrid as Gr
import BoardGame.Server.Domain.GameError (GameError(..))
import qualified Bolour.Util.MiscUtil as Util
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified Bolour.Util.Empty as Empty

-- | The game board.
data Board = Board {
    dimension :: Int
  , grid :: BlackWhiteGrid Piece
}
  deriving (Show)

-- TODO. Check rectangular. Check parameters. See below.
mkBoardFromPieces :: [[Maybe Piece]] -> Int -> Board
mkBoardFromPieces cells =
  let cellMaker row col = White $ cells !! row !! col
  in mkBoard cellMaker

mkBoardFromPiecePoints :: [PiecePoint] -> Int -> Board
mkBoardFromPiecePoints piecePoints dimension =
  let maybePiecePoint row col = find (\PiecePoint {point} -> point == Point row col) piecePoints
      pieceMaker row col =
        case maybePiecePoint row col of
          Nothing -> White Nothing
          Just (PiecePoint piece point) -> White (Just piece)
  in mkBoard pieceMaker dimension

mkEmptyBoard :: Int -> Board
mkEmptyBoard dimension =
  let grid = Gr.mkEmptyGrid dimension dimension
  in Board dimension grid

mkBoard :: (Int -> Int -> BlackWhite Piece) -> Int -> Board
mkBoard cellMaker dimension =
  let grid = Gr.mkGrid cellMaker dimension dimension
  in Board dimension grid

rows :: Board -> [[BlackWhitePoint Piece]]
rows Board {grid} = Gr.rows grid

cols :: Board -> [[BlackWhitePoint Piece]]
cols Board {grid} = Gr.cols grid

isFilled :: Board -> Bool
isFilled Board {grid} = Gr.isFilled grid

boardLine :: Board -> Axis -> Int -> [BlackWhitePoint Piece]
boardLine board Axis.X lineNumber = rows board !! lineNumber
boardLine board Axis.Y lineNumber = cols board !! lineNumber

blackWhitePointsToStrip :: Axis -> Int -> [BlackWhitePoint Piece] -> Int -> Int -> Strip
blackWhitePointsToStrip axis lineNumber blackWhitePiecePoints offset size =
  let blackWhiteChars = bwPiecePointsToBWChars blackWhitePiecePoints
  in Strip.stripFromBlackWhiteLine axis lineNumber blackWhiteChars offset size

bwPiecePointToBWChar :: BlackWhitePoint Piece -> BlackWhite Char
bwPiecePointToBWChar blackWhitePiecePoint =
  Piece.value <$> BlackWhitePoint.value blackWhitePiecePoint

bwPiecePointsToBWChars :: [BlackWhitePoint Piece] -> [BlackWhite Char]
bwPiecePointsToBWChars bwPiecePoints = bwPiecePointToBWChar <$> bwPiecePoints

stripOfBoard :: Board -> Axis -> Int -> Int -> Int -> Strip
stripOfBoard board axis lineNumber offset size =
  let theLine = boardLine board axis lineNumber
  in blackWhitePointsToStrip axis lineNumber theLine offset size

next :: Board -> Point -> Axis -> Maybe (BlackWhite Piece)
next Board {grid} point axis = BlackWhitePoint.value <$> Gr.next grid point axis

prev :: Board -> Point -> Axis -> Maybe (BlackWhite Piece)
prev Board {grid} point axis = BlackWhitePoint.value <$> Gr.prev grid point axis

adjacent :: Board -> Point -> Axis -> Int -> Maybe (BlackWhite Piece)
adjacent Board {grid} point axis direction = BlackWhitePoint.value <$> Gr.adjacent grid point axis direction

-- | Nothing if out of bounds, noPiece if empty but in bounds.
get :: Board -> Point -> BlackWhite Piece
get board @ Board { grid }  = Gr.get grid

getPiece :: Board -> Point -> Maybe Piece
getPiece board point = BlackWhite.fromWhite $ get board point

-- TODO. Rename to piecePoints.
getGridPieces :: Board -> [PiecePoint]
getGridPieces Board {grid} =
  let locatedPieces = Gr.getValues grid
      toGridPiece (piece, point) = PiecePoint piece point
  in toGridPiece <$> locatedPieces

setN :: Board -> [BlackWhitePoint Piece] -> Board
setN Board {dimension, grid} bwPiecePoints =
  let updatedGrid = Gr.setN grid bwPiecePoints
  in Board dimension updatedGrid

setPiecePoints :: Board -> [PiecePoint] -> Board
setPiecePoints board piecePoints =
  let toBWPoint PiecePoint {piece, point} = BlackWhitePoint (White (Just piece)) point
      bwPiecePoints = toBWPoint <$> piecePoints
  in setN board bwPiecePoints

setBlackPoints :: Board -> [Point] -> Board
setBlackPoints board points =
  let blackBWPoints = BlackWhitePoint Black <$> points
  in setN board blackBWPoints

isEmpty :: Board -> Bool
isEmpty Board { grid } = Empty.isEmpty grid

pointIsEmpty :: Board -> Point -> Bool
pointIsEmpty Board {grid} = Gr.isEmpty grid

pointIsNonEmpty :: Board -> Point -> Bool
pointIsNonEmpty board point = not $ pointIsEmpty board point

pointHasValue :: Board -> Point -> Bool
pointHasValue Board {grid} = Gr.hasValue grid

inBounds :: Board -> Point -> Bool
inBounds Board {grid} = Gr.inBounds grid

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

maybeBlackWhiteHasPiece :: Maybe (BlackWhite Piece) -> Bool
maybeBlackWhiteHasPiece Nothing = False
maybeBlackWhiteHasPiece (Just bwPiece) = BlackWhite.hasValue bwPiece

pointHasRealNeighbor :: Board -> Point -> Axis -> Bool
pointHasRealNeighbor board point axis =
  let maybeNext = next board point axis
      maybePrev = prev board point axis
  in maybeBlackWhiteHasPiece maybeNext || maybeBlackWhiteHasPiece maybePrev

stripOfPlay :: Board -> [PlayPiece] -> Maybe Strip
stripOfPlay board [] = Nothing
stripOfPlay board [playPiece] = stripOfPlay1 board playPiece
stripOfPlay board (pp:pps) = stripOfPlayN board (pp:pps)

stripOfPlay1 :: Board -> PlayPiece -> Maybe Strip
stripOfPlay1 board PlayPiece {point} =
  let Point {row, col} = point
      -- Arbitrarily choose the row of the single move play.
      theRow = rows board !! row
      rowAsBlackWhiteChars = bwPiecePointsToBWChars theRow
  in Just $ Strip.stripFromBlackWhiteLine Axis.X row rowAsBlackWhiteChars col 1

stripOfPlayN :: Board -> [PlayPiece] -> Maybe Strip
stripOfPlayN board playPieces =
  let points = (\PlayPiece {point} -> point) <$> playPieces
      Point {row = hdRow, col = hdCol} = head points
      maybeAxis = Point.axisOfLine points
  in
    let mkStrip axis =
          let (lineNumber, line, begin) =
                case axis of
                  Axis.X -> (hdRow, rows board !! hdRow, hdCol)
                  Axis.Y -> (hdCol, cols board !! hdCol, hdRow)
              lineAsBlackWhiteChars = bwPiecePointsToBWChars line
           in Strip.stripFromBlackWhiteLine axis lineNumber lineAsBlackWhiteChars begin (length points)
    in mkStrip <$> maybeAxis

-- | Check that a strip has no neighbors on either side - is disconnected
--   from the rest of its line. If it is has neighbors, it is not playable
--   since a matching word will run into the neighbors. However, a containing
--   strip will be playable and so we can forget about this strip.
stripIsDisconnectedInLine :: Board -> Strip -> Bool
stripIsDisconnectedInLine board (strip @ Strip {axis, begin, end, content})
  | null content = False
  | otherwise =
      let f = Strip.stripPoint strip 0
          l = Strip.stripPoint strip (end - begin)
          -- limit = dimension
          maybePrevPiece = prev board f axis
          maybeNextPiece = next board l axis
          isSeparator maybeBlackWhitePiece = not $ maybeBlackWhiteHasPiece maybeBlackWhitePiece
      in isSeparator maybePrevPiece && isSeparator maybeNextPiece

playableStrips :: Board -> Int -> [Strip]
playableStrips board trayCapacity =
  if isEmpty board
    then playableStripsForEmptyBoard board trayCapacity
    else playableStripsForNonEmptyBoard board trayCapacity

playableStripsForEmptyBoard :: Board -> Int -> [Strip]
playableStripsForEmptyBoard board @ Board {dimension} trayCapacity =
  let center = dimension `div` 2
      centerRow = rows board !! center
      centerRowAsBlackWhiteChars = bwPiecePointsToBWChars centerRow
      strips = Strip.allStripsInBlackWhiteLine Axis.X center centerRowAsBlackWhiteChars
      includesCenter Strip {begin, end} = begin <= center && end >= center
      withinTraySize Strip {begin, end} = end - begin < trayCapacity
  in (filter includesCenter . filter withinTraySize) strips

playableStripsForNonEmptyBoard :: Board -> Int -> [Strip]
playableStripsForNonEmptyBoard board trayCapacity =
  let strips = computeAllLiveStrips board
      playableBlanks Strip {blanks} = blanks > 0 && blanks <= trayCapacity
      playables = filter playableBlanks strips
      playables' = filter Strip.hasAnchor playables
      playables'' = filter (stripIsDisconnectedInLine board) playables'
   in playables''

computeAllLiveStrips :: Board -> [Strip]
computeAllLiveStrips Board {grid} = lineSegmentToStrip <$> Gr.allSegments grid

lineSegmentToStrip :: LineSegment Piece -> Strip
lineSegmentToStrip lineSegment @ LineSegment {axis, lineNumber, begin, end, segment} =
  let charLineSegment = Piece.value <$> lineSegment
  in Strip.charLineSegmentToStrip charLineSegment

enclosingStripsOfBlankPoints :: Board -> Axis -> Map.Map Point [Strip]
enclosingStripsOfBlankPoints Board {grid} axis =
  let liveStrips = lineSegmentToStrip <$> Gr.segmentsAlongAxis grid axis
      stripsEnclosingBlanks = filter Strip.hasBlanks liveStrips
  in Util.inverseMultiValuedMapping Strip.blankPoints stripsEnclosingBlanks

playableEnclosingStripsOfBlankPoints :: Board -> Axis -> Map.Map Point [Strip]
playableEnclosingStripsOfBlankPoints board axis =
  let enclosing = enclosingStripsOfBlankPoints board axis
      playable strip @ Strip {blanks, content} =
        -- blanks <= trayCapacity &&
          stripIsDisconnectedInLine board strip &&
          length content > 1 -- Can't play to a single blank strip - would have no anchor.
  in
    filter playable <$> enclosing

-- | Get all the colinear neighbors in a given direction along a given axis
--   ordered in increasing value of the line index (excluding the point
--   itself). A colinear point is considered a neighbor if it has a real value,
--   and is adjacent to the given point, or recursively adjacent to a neighbor.
lineNeighbors :: Board -> Point -> Axis -> Int -> [PiecePoint]
lineNeighbors board @ Board {grid} point axis direction =
  let piecePointPairs = Gr.lineNeighbors grid point axis direction
  in toPiecePoint <$> piecePointPairs
     where toPiecePoint (piece, point) = PiecePoint piece point