--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

{-|
A point of a grid and related definitions.

These are very unlikely to change over time and are therefore
shared with the web interface layer and with clients.
-}
module Bolour.Plane.Domain.Point (
    Axis(..)
  , crossAxis
  , Coordinate
  , Point(..)
  , Height
  , Width
  , Direction
  , forward
  , backward
  , colinearPoint
  , nthNeighbor
  , axisOfLine
) where

import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)

-- | One of the axes of the board.
--   X designates a horizontal line of the board.
--   An index value associated with X is a column number. A size is the width.
--   Y designates a vertical line of the board.
--   An index value associated with Y is a row number. A size the height.
--
--   Note however that the first coordinate of a Point is a row, and its second
--   coordinate is a column. That is probably a mistake since it is inconsistent
--   with the use of axes. But for historical reasons still remains in the code base.
data Axis = Y | X
  deriving (Eq, Show, Generic)

instance FromJSON Axis
instance ToJSON Axis

crossAxis :: Axis -> Axis
crossAxis X = Y
crossAxis Y = X

type Direction = Int

-- | Increment for going forward in a line.
forward :: Int
forward = 1
-- | Increment for going backward in a line.
backward :: Int
backward = -1

-- | A value of a board coordinate.
type Coordinate = Int
type Height = Coordinate
type Width = Coordinate

-- | The coordinates of a square on a board.
data Point = Point {
    row :: Coordinate     -- ^ The row index - top-down.
  , col :: Coordinate     -- ^ The column index - left-to-right.
}
  deriving (Eq, Ord, Show, Generic, NFData)

instance FromJSON Point
instance ToJSON Point

colinearPoint :: Point -> Axis -> Int -> Point
colinearPoint Point { row, col } axis lineCoordinate =
  case axis of
    X -> Point row lineCoordinate
    Y -> Point lineCoordinate col

nthNeighbor :: Point -> Axis -> Int -> Int -> Point
nthNeighbor Point {row, col} axis direction steps =
  let offset = steps * direction
  in case axis of
    X -> Point row (col + offset)
    Y -> Point (row + offset) col

axisOfLine :: [Point] -> Maybe Axis
axisOfLine [] = Nothing
axisOfLine line =
  let Point {row = r, col = c} = head line
      rows = row <$> line
      isXAxis = all (r ==) rows
      cols = col <$> line
      isYAxis = all (c ==) cols
  in if isXAxis && isYAxis then Nothing
     else Just $ if isXAxis then X else Y




