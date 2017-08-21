--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}

module BoardGame.Common.Domain.GameParams (
  GameParams(..)
) where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import BoardGame.Common.Domain.Point (Height, Width)

-- | Parameters used in creating a new game - provided by API clients.
--   Note. The Haskell standard for language code uses an underscore to
--   separate the language code itself from the country code, e.g., en_US. Same with Java.
--   That is the standard that has to be used in the server.
--   Browsers on the other hand use a dash separator. Beware!
--   For now, we are only supporting the generic language without the country code.
data GameParams = GameParams {
    height :: Height      -- ^ Height of the board.
  , width :: Width        -- ^ Width of the board.
  , trayCapacity :: Int   -- ^ Number of letters in a user or machine tray.
  , languageCode :: String -- ^ Language code for the language of the word list to use, e.g. "en".
  , playerName :: String  -- ^ Name of user initiating a game. TODO. Expedient. Not a game parameter per se. Move it out.
}
  deriving (Eq, Show, Generic)

instance FromJSON GameParams
instance ToJSON GameParams



