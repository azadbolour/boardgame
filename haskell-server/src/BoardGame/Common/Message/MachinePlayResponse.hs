--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Message.MachinePlayResponse (
    MachinePlayResponse(..)
  , tupleToMachinePlayResponse
  ) where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

import BoardGame.Common.Domain.PlayPiece
import BoardGame.Common.Domain.GameMiniState

data MachinePlayResponse = MachinePlayResponse {
    gameMiniState :: GameMiniState
  , playedPieces :: [PlayPiece]
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON MachinePlayResponse
instance ToJSON MachinePlayResponse

tupleToMachinePlayResponse :: (GameMiniState, [PlayPiece]) -> MachinePlayResponse
tupleToMachinePlayResponse (miniState, playPieces) =
  MachinePlayResponse miniState playPieces

