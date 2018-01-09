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

module BoardGame.Server.Domain.CrossWordFinder (
    findStripCrossWords
  , findCrossPlays
  , findCrossPlay
  ) where

import Data.Maybe (fromJust, isNothing, catMaybes)
import Data.List (transpose, find)

import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.Point (Point, Point(Point), Axis)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.PlayPiece (PlayPiece, MoveInfo)
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified Data.ByteString.Char8 as BS

forward = Axis.forward
backward = Axis.backward

-- TODO. StripMatcher should use this. See Scala version.
findStripCrossWords :: Board -> Strip -> String -> [String]
findStripCrossWords board (strip @ Strip {axis, content}) word =
  let range = [0 .. length word - 1]
      crossingIndices = filter (\i -> Piece.isEmptyChar $ content !! i) range
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
  let range = [0 .. length word - 1]
      crossingIndices = filter (\i -> Piece.isEmptyChar $ content !! i) range
      calcCrossing :: Int -> Maybe [MoveInfo] = \i ->
        let point = Strip.pointAtOffset strip i
            playedChar = word !! i
        in findCrossPlay board point playedChar (Axis.crossAxis axis)
      crossingPlays = calcCrossing <$> crossingIndices
  in catMaybes crossingPlays

-- | Find the surrounding cross play to a given move (provided as
--   the point and movingLetter parameters).
--
--   Note that the only moving piece in a cross play is the one
--   at the given crossing point.
--   Note also that the moving piece has yet to be placed on the board.
findCrossPlay :: Board -> Point -> Char -> Axis -> Maybe [MoveInfo]
findCrossPlay board point movingLetter crossAxis =
  let crossRange = Board.surroundingRange board point crossAxis
  in if length crossRange < 2 then Nothing
     else Just $ moveInfo <$> crossRange
     where moveInfo crossLinePoint =
             let moving = crossLinePoint == point
                 crossLetter =
                   if moving then movingLetter
                   else Board.getLetter board crossLinePoint
             in (crossLetter, crossLinePoint, moving)
