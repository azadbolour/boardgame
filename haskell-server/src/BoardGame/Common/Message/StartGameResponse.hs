--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Message.StartGameResponse (
  StartGameResponse(..)
  )
  where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

import BoardGame.Common.Domain.GameParams (GameParams)
import BoardGame.Common.Domain.Piece (Piece)
import Bolour.Grid.GridValue (GridValue)

-- | Data transfer object for a game.
--   The machine tray is excluded -
--   we don't want to reveal the machine's hand to client programs.
data StartGameResponse = StartGameResponse {
    gameId :: String          -- ^ The unique identifier of the game.
  , gameParams :: GameParams
  , gridPieces :: [GridValue Piece]   -- ^ The pieces in play and their positions.
  , trayPieces :: [Piece]     -- ^ The pieces on the user tray.
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON StartGameResponse
instance ToJSON StartGameResponse



