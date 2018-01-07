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
  , findCrossPlay
  ) where

import Data.Maybe (fromJust, isNothing, catMaybes)
import Data.List (transpose, find)
import Debug.Trace as Trace
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.Point (Point, Point(Point), Axis)
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.GridValue as GridValue
import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import BoardGame.Common.Domain.PlayPiece (PlayPiece, MoveInfo)
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
      crossingIndices = filter (\i -> Piece.isEmptyChar $ unpacked !! i) range
      calcCrossing :: Int -> Maybe String = \i ->
        let point = Strip.pointAtOffset strip i
            playedChar = word !! i
        in findSurroundingWord board point playedChar (Axis.crossAxis axis)
      crossingStrings = catMaybes (calcCrossing <$> crossingIndices)
      crossingWords = filter (\w -> length w > 1) crossingStrings
  in crossingWords

findSurroundingWord :: Board -> Point -> Char -> Axis -> Maybe String
findSurroundingWord board point letter axis =
  let play = findCrossPlay board point letter axis
  in ((\(char, _, _) -> char) <$>) <$> play

findCrossPlays :: Board -> [PlayPiece] -> [[MoveInfo]]
findCrossPlays (board @ Board {grid}) playPieces =
  let Grid {cells} = grid
      columns = transpose cells
      -- TODO. Internal error if fromJust fails.
      strip = fromJust $ Board.stripOfPlay board columns playPieces
      word = PlayPiece.playPiecesToWord playPieces
  in findCrossPlays' board strip word

findCrossPlays' :: Board -> Strip -> String -> [[MoveInfo]]
findCrossPlays' board (strip @ Strip {axis, content}) word =
  let l = length word
      range = [0 .. l - 1]
      unpacked = BS.unpack content
      crossingIndices = filter (\i -> Piece.isEmptyChar $ unpacked !! i) range
      calcCrossing :: Int -> Maybe [MoveInfo] = \i ->
        let point = Strip.pointAtOffset strip i
            playedChar = word !! i
        in findCrossPlay board point playedChar (Axis.crossAxis axis)
      crossingPlays = calcCrossing <$> crossingIndices
  in catMaybes crossingPlays

-- | Find the surrounding cross play to a given move (provided as the point and letter parameters).
--   Note that the only moved piece in a cross play is the one at the given crossing point.
findCrossPlay :: Board -> Point -> Char -> Axis -> Maybe [MoveInfo]
findCrossPlay board point letter axis =

  let Point {row = crossWordBeginRow, col = crossWordBeginCol} = findBoundary backwardDir
      Point {row = crossWordEndRow, col = crossWordEndCol} = findBoundary forwardDir
      surroundingRange = case axis of
        Axis.X -> [crossWordBeginCol .. crossWordEndCol]
        Axis.Y -> [crossWordBeginRow .. crossWordEndRow]

  in if length surroundingRange < 2 then Nothing
     else Just $ playInfo <$> surroundingRange

     where findBoundary = farthestNeighbor board point axis
           playInfo lineIndex =
              let neighbor = Point.colinearPoint point axis lineIndex
                  moved = neighbor == point -- The only moved point in a cross play.
                  Piece { value } = Board.getPiece board neighbor
                  ch = if moved then letter else value
              in (ch, neighbor, moved)

farthestNeighbor :: Board -> Point -> Axis -> Int -> Point
farthestNeighbor (board @ Board {dimension, grid}) point axis direction =
   -- The starting point is special since it is empty.
   -- Crossword analysis is done before the new tiles of a play are laid down.
   if (not $ Board.inBounds board neighbor) || Board.pointIsEmpty board neighbor
   then point
   else
      let neighbors = Board.nthNeighbor point axis direction <$> [1 .. dimension - 1]
      in fromJust $ find isBoundary neighbors
         where
           neighbor = Board.nthNeighbor point axis direction 1
           isBoundary pt =
             let maybeCell = Grid.adjacentCell grid pt axis direction dimension
                 maybeNextPiece = GridValue.value <$> maybeCell
                 nextPtIsEmpty = case maybeNextPiece of
                                  Nothing -> True
                                  Just piece -> Piece.isEmpty piece
             in Board.pointIsNonEmpty board pt && nextPtIsEmpty
