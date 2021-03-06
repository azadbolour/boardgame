--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}

module BoardGame.Server.Domain.Player (
    PlayerType (..)
  , userIndex, machineIndex
  , playerTypeIndex
  , Player(..)
  , encode
  , decode
) where

import GHC.Generics
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Lazy.Char8 as BC

-- | Types of players.
data PlayerType = UserPlayer | MachinePlayer
  deriving (Show, Read, Eq, Generic)

instance FromJSON PlayerType
instance ToJSON PlayerType

-- | Index of user player - for indexing into an array of user/machine.
userIndex = 0 :: Int
-- | Index of machine player - for indexing into an array of user/machine.
machineIndex = 1 :: Int

-- | Get the index of a player for indexing into an array of user/machine.
playerTypeIndex :: PlayerType -> Int
playerTypeIndex UserPlayer = userIndex
playerTypeIndex MachinePlayer = machineIndex

-- | A user player.
data Player = Player {
    playerId :: String
  , name :: String    -- ^ Unique name of the player.
}
  deriving (Eq, Show, Generic)

instance FromJSON Player
instance ToJSON Player

encode :: Player -> String
encode player = BC.unpack $ Aeson.encode player

decode :: String -> Maybe Player
decode encoded = Aeson.decode $ BC.pack encoded



