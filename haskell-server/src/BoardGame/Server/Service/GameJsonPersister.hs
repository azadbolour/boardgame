--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.GameJsonPersister (
    GameJsonPersister(..)
  , clearAllData
) where

import BoardGame.Server.Service.TypeDefs

data GameJsonPersister = GameJsonPersister {
    migrate :: Result ()
  , savePlayer :: PlayerId -> String -> JsonEncoded -> Result ()
  , findPlayerByName :: String -> Result (Maybe JsonEncoded)
  , clearPlayers :: Result ()
  , saveGame :: GameId -> PlayerId -> JsonEncoded -> Result ()
  , findGameById :: GameId -> Result (Maybe JsonEncoded)
  , deleteGame :: GameId -> Result ()
  , clearGames :: Result ()
}

clearAllData :: GameJsonPersister -> Result ()
clearAllData GameJsonPersister {clearPlayers, clearGames} = do
  clearGames
  clearPlayers


