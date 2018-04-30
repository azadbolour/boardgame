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
import BoardGame.Server.Service.GameData (GameData, GameData(GameData))
import qualified BoardGame.Server.Service.GameData as GameData
import BoardGame.Server.Domain.GameBase (GameBase, GameBase(GameBase))
import qualified BoardGame.Server.Domain.GameBase as GameBase
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
clearPlayers GameJsonPersister {clearPlayers = delegate} = delegate

saveGame :: GameJsonPersister -> Version -> GameData -> Result ()
saveGame GameJsonPersister {saveGame = delegate} version gameData @ GameData {base} = do
  let GameBase {gameId, playerId} = base
      json = VersionStamped.encodeWithVersion version gameData
  delegate gameId playerId json

findGameById :: GameJsonPersister -> String -> Result (Maybe GameData)
findGameById GameJsonPersister {findGameById = delegate} gameUid = do
  maybeJson <- delegate gameUid
  let maybeGameData = maybeJson >>= VersionStamped.decodeAndExtract
  return $ maybeGameData

deleteGame :: GameJsonPersister -> String -> Result ()
deleteGame GameJsonPersister {deleteGame = delegate} = delegate

clearGames :: GameJsonPersister -> Result ()
clearGames GameJsonPersister {clearGames = delegate} = delegate

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
