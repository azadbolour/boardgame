
--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Message.HandShakeResponse (
    HandShakeResponse(..)
  , tupleToHandShakeResponse
  ) where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

data HandShakeResponse = HandShakeResponse {
    serverType :: String
  , apiVersion :: String -- Not yet used. For the future.
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON HandShakeResponse
instance ToJSON HandShakeResponse

tupleToHandShakeResponse :: (String, String) -> HandShakeResponse
tupleToHandShakeResponse (serverType, apiVersion) =
  HandShakeResponse serverType apiVersion


