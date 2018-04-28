--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Domain.GameTransitions where

import Data.Sequence (Seq)
import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)

import BoardGame.Server.Domain.Play (Play)
import BoardGame.Server.Domain.GameBase (GameBase)

data GameTransitions = GameTransitions {
    base :: GameBase
  , plays :: Seq Play
}
  deriving (Eq, Show, Generic)

instance FromJSON GameTransitions
instance ToJSON GameTransitions

