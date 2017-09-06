--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE RankNTypes #-}

module BoardGame.Server.Domain.GameEnv (
    GameEnv(..)
 )
where


import Bolour.Util.PersistRunner (ConnectionProvider)
import BoardGame.Server.Domain.ServerConfig (ServerConfig)
import BoardGame.Server.Domain.GameCache (GameCache)
import BoardGame.Server.Domain.DictionaryCache (DictionaryCache)

data GameEnv = GameEnv {
    serverConfig :: ServerConfig
  , connectionProvider :: ConnectionProvider
  , gameCache :: GameCache
  , dictionaryCache :: DictionaryCache
}



