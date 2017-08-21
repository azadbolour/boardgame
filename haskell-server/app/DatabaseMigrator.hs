--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Main where

import System.Environment (getArgs)
import qualified BoardGame.Server.Domain.GameConfig as Config
import Bolour.Util.DbUtil (makePool)
import BoardGame.Server.Service.GameDao (migrateDatabase)
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters

main :: IO ()

-- TODO. Use getOpt. from System.Console.GetOpt.

main = do
    args <- getArgs
    let maybeConfigPath = if null args then Nothing else Just $ head args
    serverParameters <- Config.getServerParameters maybeConfigPath
    let ServerParameters.ServerParameters {deployEnv} = serverParameters
    myPool <- makePool serverParameters
    config <- Config.mkConfig serverParameters myPool
    migrateDatabase myPool

