--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Message.PlayerDto (
    PlayerDto
  , PlayerDto(PlayerDto)
  )
  where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

-- | Data transfer object for a player.
data GameDto = GameDto {
  name :: String
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON PlayerDto
instance ToJSON PlayerDto



