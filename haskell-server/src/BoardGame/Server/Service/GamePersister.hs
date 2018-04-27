--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.GamePersister (
    GamePersister(..)
  , clearAllData
) where

import BoardGame.Server.Service.TypeDefs (Result)
import BoardGame.Server.Domain.Player (Player)
import BoardGame.Server.Domain.Game (Game)
import BoardGame.Server.Domain.GameError (GameError)

data GamePersister = GamePersister {
    migrate :: Result ()
  , savePlayer :: Player -> Result ()
  , findPlayerByName :: String -> Result (Maybe Player)
  , clearPlayers :: Result ()
  , saveGame :: Game -> Result ()
  , findGameById :: String -> Result (Maybe Game)
  , deleteGame :: String -> Result ()
  , clearGames :: Result ()
}

clearAllData :: GamePersister -> Result ()
clearAllData GamePersister {clearPlayers, clearGames} = do
  clearGames
  clearPlayers


