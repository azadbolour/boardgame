--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Server.Domain.GameEnv (
    GameEnv(..)
 )
where

import BoardGame.Server.Domain.GameConfig (Config)
import Bolour.Util.StaticTextFileCache (TextFileCacheType)
import BoardGame.Server.Domain.GameCache (GameCache)

data GameEnv = GameEnv {
  config :: Config,
  cache :: GameCache,
  dictionaryCache :: TextFileCacheType
}



