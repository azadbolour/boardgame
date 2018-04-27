--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Main where

import System.Exit (die)
import Data.Either (isLeft)
import System.Environment (getArgs)
import Control.Monad.Trans.Except (runExceptT)
import Control.Monad (when)
import qualified Bolour.Util.PersistRunner as PersistRunner
import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig
import qualified BoardGame.Server.Service.GameDao as GameDao
import qualified BoardGame.Server.Service.GameService as GameService
import BoardGame.Server.Domain.GameEnv (GameEnv(..))
import qualified BoardGame.Server.Domain.GameEnv as GameEnv
import qualified BoardGame.Server.Service.GameTransformerStack as TransformerStack

main :: IO ()

-- TODO. Use getOpt. from System.Console.GetOpt.

main = do
    args <- getArgs
    let maybeConfigPath = if null args then Nothing else Just $ head args
    serverConfig <- ServerConfig.getServerConfig maybeConfigPath
    -- gameEnv <- GameEnv.mkGameEnv serverConfig
    eitherGameEnv <- runExceptT $ GameEnv.mkGameEnv serverConfig
    when (isLeft eitherGameEnv) $
      die $ "unable to initialize the application environment for server config " ++ show serverConfig
    let Right gameEnv = eitherGameEnv
    runExceptT $ TransformerStack.runDefault gameEnv $
      GameService.addPlayerService $ GameService.unknownPlayerName
    return ()
