
--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Message.SwapPieceResponse (
    SwapPieceResponse(..)
  , tupleToSwapPieceResponse
  ) where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

import BoardGame.Common.Domain.Piece
import BoardGame.Common.Domain.GameMiniState

data SwapPieceResponse = SwapPieceResponse {
    gameMiniState :: GameMiniState
  , piece :: Piece
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON SwapPieceResponse
instance ToJSON SwapPieceResponse

tupleToSwapPieceResponse :: (GameMiniState, Piece) -> SwapPieceResponse
tupleToSwapPieceResponse (miniState, piece) =
  SwapPieceResponse miniState piece


