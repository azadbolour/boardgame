--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Main where

import System.Exit (die)
import System.Environment (getArgs)
import Control.Monad.Trans.Except (runExceptT)
import Control.Monad (when)
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig
import qualified BoardGame.Server.Service.GameService as GameService
import qualified BoardGame.Server.Domain.GameEnv as GameEnv
import qualified BoardGame.Server.Service.GameTransformerStack as TransformerStack

main :: IO ()

-- TODO. Use getOpt. from System.Console.GetOpt.

main = do
    args <- getArgs
    when (null args) $ print "Beware! No config file supplied as argument - using default config parameters."
    let maybeConfigPath = if null args then Nothing else Just $ head args
    serverConfig <- ServerConfig.getServerConfig maybeConfigPath
    -- TODO. Do not print db password - should not be in server config.
    print $ "server config - " ++ show serverConfig
    eitherGameEnv <- runExceptT $ GameEnv.mkGameEnv serverConfig
    case eitherGameEnv of
      Left error -> do
        let message = "unable to initialize the application environment - "
        die $ message ++ show error
      Right gameEnv -> do
        runExceptT $ TransformerStack.runDefault gameEnv $
          GameService.addPlayerService GameService.unknownPlayerName
        print "OK"
