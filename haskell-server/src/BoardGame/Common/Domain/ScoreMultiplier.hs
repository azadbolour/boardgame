--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Common.Domain.ScoreMultiplier (
    ScoreMultiplier(..)
  , noMultiplier
  ) where

import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.ScoreMultiplierType (ScoreMultiplierType)
import qualified BoardGame.Common.Domain.ScoreMultiplierType as SMType
import BoardGame.Common.Domain.PointSymmetry (
    reflectOnFirstOctant
  , translateOrigin
  )

data ScoreMultiplier = ScoreMultiplier {
  scoreMultiplierType :: ScoreMultiplierType,
  factor :: Int
}

noMultiplier :: ScoreMultiplier
noMultiplier = ScoreMultiplier SMType.None 1

letterMultiplier :: Int -> ScoreMultiplier
letterMultiplier = ScoreMultiplier SMType.Letter

wordMultiplier :: Int -> ScoreMultiplier
wordMultiplier = ScoreMultiplier SMType.Word

scoreMultiplier :: Point -> Int -> ScoreMultiplier
scoreMultiplier point dimension =
  let center = dimension `div` 2
      centerOrigin = Point center center
      pointRelativeToCenter = translateOrigin centerOrigin point
  in multiplierRelativeToCenter pointRelativeToCenter dimension

multiplierRelativeToCenter :: Point -> Int -> ScoreMultiplier
multiplierRelativeToCenter point dimension =
  let representative = reflectOnFirstOctant point
  in multiplierForFirstOctantRelativeToCenter representative dimension

multiplierForFirstOctantRelativeToCenter :: Point -> Int -> ScoreMultiplier
multiplierForFirstOctantRelativeToCenter (point @ Point {row, col}) dimension =
  let bound = dimension `div` 2
      quarter = bound `div` 2
      isCornerPoint = point == Point bound bound
      isMidEdgePoint = point == Point 0 bound
      isCenterPoint = point == Point 0 0
      isDiagonalPoint centerOffset = col - row == centerOffset
      isQuarterEdgePoint = row == quarter && col == bound
  in
      if isCenterPoint then wordMultiplier 2
      else if isCornerPoint then wordMultiplier 3
      else if isMidEdgePoint then wordMultiplier 3
      else if isQuarterEdgePoint then letterMultiplier 2
      else if isDiagonalPoint 0 then
        case row of
          1 -> letterMultiplier 2
          2 -> letterMultiplier 3
          _ -> wordMultiplier 2
      else if isDiagonalPoint (quarter + 1) then
        let nextToMiddle = bound - 1
        in case col of
             bound -> noMultiplier
             nextToMiddle -> letterMultiplier 3 -- TODO. Generates overlapped pattern warning.
             _ -> letterMultiplier 2
      else
        noMultiplier

-- TODO. Best practices for alternatives of Int based on other ints.








