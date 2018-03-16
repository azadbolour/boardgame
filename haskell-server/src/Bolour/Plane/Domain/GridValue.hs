--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE StandaloneDeriving #-}

module Bolour.Plane.Domain.GridValue (
    GridValue(..)
)
where

import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)
import Bolour.Plane.Domain.Point (Point)

-- | A value located on a grid.
data GridValue val = GridValue {
    value :: val      -- ^ The value.
  , point :: Point    -- ^ The position of the piece on the grid.
}

deriving instance (Eq val) => Eq (GridValue val)
deriving instance (Show val) => Show (GridValue val)
deriving instance (Generic val) => Generic (GridValue val)
deriving instance (Generic val, FromJSON val) => FromJSON (GridValue val)
deriving instance (Generic val, ToJSON val) => ToJSON (GridValue val)
deriving instance (Generic val, NFData val) => NFData (GridValue val)
