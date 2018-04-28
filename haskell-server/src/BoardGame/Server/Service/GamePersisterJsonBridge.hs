--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.GamePersisterJsonBridge (
    mkBridge
)
where

import Bolour.Util.VersionStamped (Version, VersionStamped, VersionStamped(VersionStamped))
import qualified Bolour.Util.VersionStamped as VersionStamped
import BoardGame.Server.Domain.Player (Player, Player(Player))
import qualified BoardGame.Server.Domain.Player as Player
import BoardGame.Server.Domain.Game (Game)
import BoardGame.Server.Domain.GameError (GameError)
import BoardGame.Server.Service.TypeDefs (Result)
import BoardGame.Server.Service.GamePersister (GamePersister, GamePersister(GamePersister))
import BoardGame.Server.Service.GameJsonPersister (GameJsonPersister, GameJsonPersister(GameJsonPersister))
import qualified BoardGame.Server.Service.GameJsonPersister as GameJsonPersister

migrate :: GameJsonPersister -> Result ()
migrate GameJsonPersister {savePlayer = delegate} =
  return ()

savePlayer :: GameJsonPersister -> Version -> Player -> Result ()
savePlayer GameJsonPersister {savePlayer = delegate} version player @ Player {playerId, name} = do
  let json = VersionStamped.encodeWithVersion version player
  delegate playerId name json

findPlayerByName :: GameJsonPersister -> String -> Result (Maybe Player)
findPlayerByName GameJsonPersister {findPlayerByName = delegate} playerName = do
  maybeJson <- delegate playerName
  return $ maybeJson >>= VersionStamped.decodeAndExtract

clearPlayers :: GameJsonPersister -> Result ()
clearPlayers GameJsonPersister {clearPlayers = delegate} =
  return ()

saveGame :: GameJsonPersister -> Version -> Game -> Result ()
saveGame GameJsonPersister {saveGame = delegate} version game =
  return ()

findGameById :: GameJsonPersister -> String -> Result (Maybe Game)
findGameById GameJsonPersister {findGameById = delegate} gameUid =
  return Nothing

deleteGame :: GameJsonPersister -> String -> Result ()
deleteGame GameJsonPersister {deleteGame = delegate} gameUid =
  return ()

clearGames :: GameJsonPersister -> Result ()
clearGames GameJsonPersister {clearGames = delegate} =
  return ()

mkBridge :: GameJsonPersister -> Version -> GamePersister
mkBridge jsonPersister version =
  GamePersister
    (migrate jsonPersister)
    (savePlayer jsonPersister version)
    (findPlayerByName jsonPersister)
    (clearPlayers jsonPersister)
    (saveGame jsonPersister version)
    (findGameById jsonPersister)
    (deleteGame jsonPersister)
    (clearGames jsonPersister)
