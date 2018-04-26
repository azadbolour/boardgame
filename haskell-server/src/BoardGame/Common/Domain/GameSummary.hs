--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Domain.GameSummary (
  GameSummary(..)
) where

import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)
import BoardGame.Common.Domain.StopInfo (StopInfo)

-- | Summary of the game at the end.
data GameSummary = GameSummary {
    stopInfo :: StopInfo
}
  deriving (Eq, Show, Generic, NFData)
  
instance FromJSON GameSummary
instance ToJSON GameSummary

