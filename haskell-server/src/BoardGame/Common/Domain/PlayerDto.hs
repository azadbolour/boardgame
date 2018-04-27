--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}

module BoardGame.Common.Domain.PlayerDto (
    PlayerDto(..)
) where

import GHC.Generics
import Data.Aeson

-- | Player data transfer object.
data PlayerDto = PlayerDto {
  name :: String
}
  deriving (Eq, Show, Generic)

instance FromJSON PlayerDto
instance ToJSON PlayerDto



