--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.ServerParametersSpec where

import Test.Hspec

import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig), DeployEnv(..))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig

spec :: Spec
spec = do
  describe "read properties" $ do
    it "read properties" $ do
        serverParameters <- ServerConfig.getServerConfig $ Just "test-data/test-config.yml"
        print serverParameters