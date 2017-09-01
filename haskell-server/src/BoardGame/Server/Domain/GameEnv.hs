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
import BoardGame.Server.Domain.GameCache (GameCache)
import BoardGame.Server.Domain.DictionaryCache (DictionaryCache)
import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary)

data LanguageDictionary dictionary => GameEnv dictionary = GameEnv {
  config :: Config,
  gameCache :: GameCache,
  dictionaryCache :: DictionaryCache dictionary
}



