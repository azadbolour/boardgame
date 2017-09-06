--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Main where

import System.Environment (getArgs)
import qualified Bolour.Util.PersistRunner as PersistRunner
import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig
import qualified BoardGame.Server.Service.GameDao as GameDao

main :: IO ()

-- TODO. Use getOpt. from System.Console.GetOpt.

main = do
    args <- getArgs
    let maybeConfigPath = if null args then Nothing else Just $ head args
    serverConfig <- ServerConfig.getServerConfig maybeConfigPath
    let ServerConfig {dbConfig} = serverConfig
    connectionProvider <- PersistRunner.mkConnectionProvider dbConfig
    GameDao.migrateDb connectionProvider
    -- PersistRunner.migrateDatabase connectionProvider GameDao.migration

