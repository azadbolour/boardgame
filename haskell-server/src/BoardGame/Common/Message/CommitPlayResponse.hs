
--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Message.CommitPlayResponse (
    CommitPlayResponse(..)
  , tupleToCommitPlayResponse
  ) where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

import BoardGame.Common.Domain.Piece

data CommitPlayResponse = CommitPlayResponse {
  playScore :: Int,
  replacementPieces :: [Piece]
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON CommitPlayResponse
instance ToJSON CommitPlayResponse

tupleToCommitPlayResponse :: (Int, [Piece]) -> CommitPlayResponse
tupleToCommitPlayResponse (score, replacementPieces) = CommitPlayResponse score replacementPieces


