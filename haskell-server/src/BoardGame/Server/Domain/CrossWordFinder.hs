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
import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified Data.ByteString.Char8 as BS

-- TODO. Move direction constants to a util module.
forward = Axis.forward
backward = Axis.backward

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
findCrossPlays board playPieces =
  let columns = Board.colsAsPieces board
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

  -- TODO. Move to a function findSurroundingRange in SwissCheeseGrid.
  let Point {row = crossWordBeginRow, col = crossWordBeginCol} = findBoundary backward
      Point {row = crossWordEndRow, col = crossWordEndCol} = findBoundary forward
      surroundingRange = case axis of
        Axis.X -> [crossWordBeginCol .. crossWordEndCol]
        Axis.Y -> [crossWordBeginRow .. crossWordEndRow]
  -- End to do.

  in if length surroundingRange < 2 then Nothing
     else Just $ playInfo <$> surroundingRange

     where findBoundary = Board.farthestNeighbor board point axis
           playInfo lineIndex =
              let neighbor = Point.colinearPoint point axis lineIndex
                  -- The only moved point in a cross play is the point itself.
                  moved = neighbor == point
                  -- lineIndex is always valid - hence so is the neighbor
                  Piece { value } = fromJust $ Board.get board neighbor
                  ch = if moved then letter else value
              in (ch, neighbor, moved)

-- TODO. This functionality was moved to SwissCheeseGrid.
-- Remove from here and add a relay call in Board.
-- farthestNeighbor :: Board -> Point -> Axis -> Int -> Point
-- farthestNeighbor board point axis direction =
--    -- The starting point is special since it is empty.
--    -- Crossword analysis is done before the new tiles of a play are laid down.
--    if (not $ Board.inBounds board neighbor) || Board.pointIsEmpty board neighbor
--    then point
--    else
--       let dimension = Board.dimension board
--           neighbors = Point.nthNeighbor point axis direction <$> [1 .. dimension - 1]
--       in fromJust $ find isBoundary neighbors
--          where
--            neighbor = Point.nthNeighbor point axis direction 1
--            isBoundary pt =
--              let dimension = Board.dimension board
--                  maybeNextPiece = Board.adjacent board pt axis direction
--                  -- maybeNextPiece = GridValue.value <$> maybeCell
--                  nextPtIsEmpty = case maybeNextPiece of
--                                   Nothing -> True
--                                   Just piece -> Piece.isEmpty piece
--              in Board.pointIsNonEmpty board pt && nextPtIsEmpty
