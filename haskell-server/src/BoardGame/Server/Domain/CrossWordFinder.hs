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
  ) where

import qualified BoardGame.Common.Domain.Point as Axis
import BoardGame.Common.Domain.Point (Point, Point(Point), Axis)
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import BoardGame.Server.Domain.Board (Board)
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified Data.ByteString.Char8 as BS

-- TODO. StripMatcher should use this. See Scala version.
findStripCrossWords :: Board -> Strip -> String -> [String]
findStripCrossWords board (strip @ Strip {axis, content}) word =
  let l = length word
      range = [0 .. l - 1]
      unpacked = BS.unpack content
      crossingIndices = filter (\i -> Piece.charIsBlank $ unpacked !! i) range
      calcCrossing :: Int -> String = \i ->
        let point = Strip.pointAtOffset strip i
            playedChar = word !! i
        in findSurroundingWord board point playedChar (Axis.crossAxis axis)
      crossingStrings = calcCrossing <$> crossingIndices
      crossingWords = filter (\w -> length w > 1) crossingStrings
  in crossingWords

findSurroundingWord :: Board -> Point -> Char -> Axis -> String
findSurroundingWord board point letter axis = ""

findCrossPlays :: Board -> [PlayPiece] -> [[(Char, Point, Bool)]]
findCrossPlays board playPieces = []

-- TODO. Implement all functions of CrossWordFinder.

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




