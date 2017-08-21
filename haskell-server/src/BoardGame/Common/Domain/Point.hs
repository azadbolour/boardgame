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
module BoardGame.Common.Domain.Point (
    Axis(..)
  , Coordinate
  , Height
  , Width
  , Point(..)
) where

import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)

-- | One of the axes of the board - Y for height (row), X for width (col).
data Axis = Y | X
  deriving (Eq, Show, Generic)

instance FromJSON Axis
instance ToJSON Axis

-- | A value of a board coordinate.
type Coordinate = Int

-- | A value of the Y (height/row) coordinate on a board.
type Height = Coordinate

-- | A value of the X (width/col) coordinate on a board.
type Width = Coordinate

-- | The coordinates of a square on a board.
data Point = Point {
    row :: Height     -- ^ The row index - top-down.
  , col :: Width      -- ^ The column index - left-to-right.
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON Point
instance ToJSON Point



