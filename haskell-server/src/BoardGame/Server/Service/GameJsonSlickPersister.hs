--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.GameJsonSlickPersister (
  mkPersister
) where

import BoardGame.Server.Service.TypeDefs
import BoardGame.Server.Service.GameJsonPersister (GameJsonPersister, GameJsonPersister(GameJsonPersister))

mkPersister :: GameJsonPersister
mkPersister =
  GameJsonPersister
    migrate
    savePlayer
    findPlayerByName
    clearPlayers
    saveGame
    findGameById
    deleteGame
    clearGames

migrate :: Result ()
migrate =
  return ()

savePlayer :: PlayerId -> String -> JsonEncoded -> Result ()
savePlayer playerId playerName json =
  return ()

findPlayerByName :: String -> Result (Maybe JsonEncoded)
findPlayerByName playerName =
  return Nothing

clearPlayers :: Result ()
clearPlayers =
  return ()

saveGame :: GameId -> PlayerId -> JsonEncoded -> Result ()
saveGame gameId playerId json =
  return ()

findGameById :: GameId -> Result (Maybe JsonEncoded)
findGameById gameId =
  return Nothing

deleteGame :: GameId -> Result ()
deleteGame gameId =
  return ()

clearGames :: Result ()
clearGames =
  return ()


