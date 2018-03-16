--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

{-|
X and Y axis and related types.
-}
module Bolour.Plane.Domain.Axis (
    Axis(..)
  , crossAxis
  , Coordinate
  , Height
  , Width
  , Direction
  , forward
  , backward
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




