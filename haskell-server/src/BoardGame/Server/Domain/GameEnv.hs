--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Domain.GameEnv (
    GameEnv(..)
  , mkGameEnv
 )
where

import Bolour.Util.PersistRunner (ConnectionProvider)
import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig
import BoardGame.Server.Domain.GameCache (GameCache, GameCache(GameCache))
import qualified BoardGame.Server.Domain.GameCache as GameCache
import BoardGame.Server.Domain.DictionaryCache (DictionaryCache)
import qualified BoardGame.Server.Domain.DictionaryCache as DictCache
import qualified Bolour.Util.PersistRunner as PersistRunner

data GameEnv = GameEnv {
    serverConfig :: ServerConfig
  , connectionProvider :: ConnectionProvider
  , gameCache :: GameCache
  , dictionaryCache :: DictionaryCache
}

mkGameEnv :: ServerConfig -> IO GameEnv
mkGameEnv serverConfig = do
    let ServerConfig {maxActiveGames, dictionaryDir, dbConfig} = serverConfig
    connectionProvider <- PersistRunner.mkConnectionProvider dbConfig
    gameCache <- GameCache.mkGameCache maxActiveGames
    dictionaryCache <- DictCache.mkCache dictionaryDir ServerConfig.maxDictionaries
    return $ GameEnv serverConfig connectionProvider gameCache dictionaryCache




