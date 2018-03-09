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

import qualified Bolour.Language.Util.WordUtil as WordUtil
import qualified Bolour.Plane.Domain.Axis as Axis
import qualified Bolour.Plane.Domain.Point as Point
import Bolour.Plane.Domain.Axis (Axis)
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.GridValue
import Bolour.Plane.Domain.GridValue (GridValue, GridValue(GridValue))
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

findStripCrossWords :: Board -> Strip -> String -> [String]
findStripCrossWords board (strip @ Strip {axis, content}) word =
  let range = [0 .. length word - 1]
      crossingIndices = filter (\i -> WordUtil.isBlankChar $ content !! i) range
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

-- | Find the surrounding cross play to a given move (provided as
--   the point and movingLetter parameters).
--
--   Note that the only moving piece in a cross play is the one
--   at the given crossing point.
--   Note also that the moving piece has yet to be placed on the board.
findCrossPlay :: Board -> Point -> Char -> Axis -> Maybe [MoveInfo]
findCrossPlay board point movingLetter crossAxis =
  let crossingMoveInfo = (movingLetter, point, True)
      forthNeighbors = Board.lineNeighbors board point crossAxis Axis.forward
      backNeighbors = Board.lineNeighbors board point crossAxis Axis.backward
      moveInfo neighbor =
        let GridValue {value = piece, point} = neighbor
        in (Piece.value piece, point, False)
  in if null backNeighbors && null forthNeighbors then Nothing
     else Just $ (moveInfo <$> backNeighbors) ++ [crossingMoveInfo] ++ (moveInfo <$> forthNeighbors)

-- | Not used for now but is needed when scores of cross plays figure in the total score.
findCrossPlays :: Board -> [PlayPiece] -> [[MoveInfo]]
findCrossPlays board playPieces =
  let -- TODO. Internal error if fromJust fails.
      strip = fromJust $ Board.stripOfPlay board playPieces
      word = PlayPiece.playPiecesToWord playPieces
  in findCrossPlays' board strip word

findCrossPlays' :: Board -> Strip -> String -> [[MoveInfo]]
findCrossPlays' board (strip @ Strip {axis, content}) word =
  let range = [0 .. length word - 1]
      crossingIndices = filter (\i -> WordUtil.isBlankChar $ content !! i) range
      calcCrossing :: Int -> Maybe [MoveInfo] = \i ->
        let point = Strip.pointAtOffset strip i
            playedChar = word !! i
        in findCrossPlay board point playedChar (Axis.crossAxis axis)
      crossingPlays = calcCrossing <$> crossingIndices
  in catMaybes crossingPlays



