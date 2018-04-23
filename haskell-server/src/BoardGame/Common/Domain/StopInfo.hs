--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Domain.StopInfo (
  StopInfo(..)
) where

import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)

data StopInfo = StopInfo {
    successivePasses :: Int
  , filledBoard :: Bool
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON StopInfo
instance ToJSON StopInfo

