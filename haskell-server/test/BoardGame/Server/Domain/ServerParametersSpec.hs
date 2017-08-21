--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.ServerParametersSpec where

import Test.Hspec

import BoardGame.Server.Domain.GameConfig (ServerParameters)
import qualified BoardGame.Server.Domain.GameConfig as Config (getServerParameters)

spec :: Spec
spec = do
  describe "read properties" $ do
    it "read properties" $ do
        serverParameters <- Config.getServerParameters $ Just "test-data/test-config.yml"
        print serverParameters