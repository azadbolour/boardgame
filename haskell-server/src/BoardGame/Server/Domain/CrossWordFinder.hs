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
  ) where

import BoardGame.Common.Domain.Point (Point, Point(Point), Axis)
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import BoardGame.Server.Domain.Board (Board)
import BoardGame.Server.Domain.Strip (Strip)

findStripCrossWords :: Board -> Strip -> String -> [String]
findStripCrossWords board strip word = [] -- TODO. Implement.

findSurroundingWord :: Board -> Point -> Char -> Axis -> String
findSurroundingWord board point letter axis = ""

findStripCrossPlays :: Board -> [PlayPiece] -> [[(Char, Point, Bool)]]
findStripCrossPlays board playPieces = []

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




