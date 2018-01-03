--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- TODO. This module is an initial draft - not tested or used yet.
-- TODO. Implement the low-level function: findSurroundingPlay. See Scala server.
-- TODO. Make sure blanks vs null chars are treated properly.
-- See comments below.
-- TODO. Then create tests for it.
module BoardGame.Server.Domain.CrossWordFinder (
    findStripCrossWords
  , findCrossPlays
  ) where

import Data.Maybe (fromJust, isNothing)
import Data.List (transpose, find)
import qualified BoardGame.Common.Domain.Point as Axis
import BoardGame.Common.Domain.Point (Point, Point(Point), Axis)
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.GridValue as GridValue
import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Server.Domain.Board (Board, Board(Board))
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Common.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Common.Domain.Grid as Grid
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified Data.ByteString.Char8 as BS

-- TODO. Move direction constants to a util module.
forwardDir = 1
backwardDir = -1

-- TODO. StripMatcher should use this. See Scala version.
findStripCrossWords :: Board -> Strip -> String -> [String]
findStripCrossWords board (strip @ Strip {axis, content}) word =
  let l = length word
      range = [0 .. l - 1]
      unpacked = BS.unpack content
      -- TODO. Should really check for blank.
      -- Do not use charIsBlank which checks for null.
      -- Clean up the mess.
      crossingIndices = filter (\i -> Piece.charIsBlank $ unpacked !! i) range
      calcCrossing :: Int -> String = \i ->
        let point = Strip.pointAtOffset strip i
            playedChar = word !! i
        in findSurroundingWord board point playedChar (Axis.crossAxis axis)
      crossingStrings = calcCrossing <$> crossingIndices
      crossingWords = filter (\w -> length w > 1) crossingStrings
  in crossingWords

findSurroundingWord :: Board -> Point -> Char -> Axis -> String
findSurroundingWord board point letter axis =
  let play = findCrossPlay board point letter axis
  in (\(char, _, _) -> char) <$> play

findCrossPlays :: Board -> [PlayPiece] -> [[(Char, Point, Bool)]]
findCrossPlays (board @ Board {grid}) playPieces =
  let Grid {cells} = grid
      -- TODO. Columns should be a member of grid. Refactor grid.
      -- So columns computation can be reused.
      columns = transpose cells
      -- TODO. Internal error if fromJust fails.
      strip = fromJust $ Board.stripOfPlay board columns playPieces
      word = PlayPiece.playPiecesToWord playPieces
  in findCrossPlays' board strip word

findCrossPlays' :: Board -> Strip -> String -> [[(Char, Point, Bool)]]
findCrossPlays' board (strip @ Strip {axis, content}) word =
  let l = length word
      range = [0 .. l - 1]
      unpacked = BS.unpack content
      -- TODO. Clean up charIsBlank. As defined it is not what we need here.
      crossingIndices = filter (\i -> Piece.charIsBlank $ unpacked !! i) range
      calcCrossing :: Int -> [(Char, Point, Bool)] = \i ->
        let point = Strip.pointAtOffset strip i
            playedChar = word !! i
        in findCrossPlay board point playedChar (Axis.crossAxis axis)
      crossingPlays = calcCrossing <$> crossingIndices
  in crossingPlays

-- | Find the surrounding cross play to a given move (provided as the point and letter parameters).
--   Note that the only moved piece in a cross play is the one at the given crossing point.
findCrossPlay :: Board -> Point -> Char -> Axis -> [(Char, Point, Bool)]
findCrossPlay board point letter axis =

  let Point {row = beforeRow, col = beforeCol} = findBoundary backwardDir
      Point {row = afterRow, col = afterCol} = findBoundary forwardDir
      surroundingRange = case axis of
        Axis.X -> [beforeCol, afterCol]
        Axis.Y -> [beforeRow, afterRow]

  in playInfo <$> surroundingRange

     where findBoundary = farthestNeighbor board point axis
           playInfo stepsToNeighbor =
              let neighbor = colinearPoint point axis stepsToNeighbor
                  moved = neighbor == point -- The only moved point in a cross play.
              in boardPointInfo board neighbor moved

boardPointInfo :: Board -> Point -> Bool -> (Char, Point, Bool)
boardPointInfo board point moved =
  let Piece { value } = Board.getPiece board point
  in (value, point, moved)

nthNeighbor :: Point -> Axis -> Int -> Int -> Point
nthNeighbor Point {row, col} axis steps direction =
  let offset = steps * direction
  in case axis of
       Axis.X -> Point row (col + offset)
       Axis.Y -> Point (row + offset) col

inBounds :: Point -> Int -> Bool
inBounds Point {row, col} dimension =
  row >= 0 && row < dimension && col >= 0 && col < dimension

hasNoLetter :: Maybe Piece -> Bool
hasNoLetter maybePiece = isNothing maybePiece || Piece.isEmpty (fromJust maybePiece)

colinearPoint :: Point -> Axis -> Int -> Point
colinearPoint Point { row, col } axis lineCoordinate =
  case axis of
    Axis.X -> Point row lineCoordinate
    Axis.Y -> Point lineCoordinate col

farthestNeighbor :: Board -> Point -> Axis -> Int -> Point
farthestNeighbor (board @ Board {dimension, grid}) point axis direction =
   -- The starting point is special since it is empty. TODO. Is it really? Check.
   if not (inBounds neighbor dimension || Board.pointIsEmpty board neighbor)
   then point
   else
      let neighbors = nthNeighbor point axis direction <$> [1 .. dimension - 1]
      in fromJust $ find isBoundary neighbors
         where
           neighbor = nthNeighbor point axis direction 1
           isBoundary pt =
             let maybeCell = Grid.adjacentCell grid pt axis direction dimension
                 maybeNextPiece = GridValue.value <$> maybeCell
             in not (Board.pointIsEmpty board pt) && hasNoLetter maybeNextPiece
