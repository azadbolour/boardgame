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
  , crossAxis
  , Coordinate
  , Height
  , Width
  , Point(..)
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

-- | A value of a board coordinate.
type Coordinate = Int

-- | A value of the Y (height/row) coordinate on a board.
type Height = Coordinate

-- | A value of the X (width/col) coordinate on a board.
type Width = Coordinate

-- | The coordinates of a square on a board.
--   TODO. Refactor to use x and y as coordinates consistent with axes X and Y.
--   BEWARE! That would reverse the roles of the coordinates.
data Point = Point {
    row :: Height     -- ^ The row index - top-down.
  , col :: Width      -- ^ The column index - left-to-right.
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON Point
instance ToJSON Point



