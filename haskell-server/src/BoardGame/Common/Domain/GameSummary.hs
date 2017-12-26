--
-- Copyright 2017 Azad Bolour
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

data GameSummary = GameSummary {
    stopInfo :: StopInfo
  , endOfPlayScores :: [Int]
  , totalScores :: [Int]
}
  deriving (Eq, Show, Generic, NFData)
  
instance FromJSON GameSummary
instance ToJSON GameSummary

