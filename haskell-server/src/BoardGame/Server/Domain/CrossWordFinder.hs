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

import Data.Maybe (fromJust)
import Data.List (transpose)
import qualified BoardGame.Common.Domain.Point as Axis
import BoardGame.Common.Domain.Point (Point, Point(Point), Axis)
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Server.Domain.Board (Board, Board(Board))
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Common.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Common.Domain.Grid as Grid
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified Data.ByteString.Char8 as BS

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
  let play = findSurroundingPlay board point letter axis
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
        in findSurroundingPlay board point playedChar (Axis.crossAxis axis)
      crossingPlays = calcCrossing <$> crossingIndices
  in crossingPlays

findSurroundingPlay :: Board -> Point -> Char -> Axis -> [(Char, Point, Bool)]
findSurroundingPlay board point letter axis =
  let closestFilledBoundary :: Point -> Int -> Point =
        \p i ->
          let hasNoLetter :: Maybe Piece -> Bool = \maybePiece -> False
              nextPiece :: Point -> Maybe Piece = \point -> Nothing
              pointIsEmpty :: Point -> Bool = \point -> False
              isBoundary :: Point -> Bool = \point -> False
              inBounds :: Point -> Bool = \point -> True
              crossPoint :: Int -> Point = \i -> Point 0 0
              crossPt1 = crossPoint 1
          in Point 0 0
  in [] -- TODO. Implement.




