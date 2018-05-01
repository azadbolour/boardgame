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

import Control.Monad.IO.Class (liftIO)
import qualified Data.Sequence as Sequence
import Bolour.Util.VersionStamped (Version, VersionStamped, VersionStamped(VersionStamped))
import qualified Bolour.Util.VersionStamped as VersionStamped
import BoardGame.Server.Domain.Player (Player, Player(Player))
import BoardGame.Server.Domain.Play (Play(WordPlay), BasePlay(..))
import qualified BoardGame.Server.Domain.Play as Play
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
migrate GameJsonPersister {migrate = delegate} =
  delegate

savePlayer :: GameJsonPersister -> Version -> Player -> Result ()
savePlayer GameJsonPersister {addPlayer = delegate} version player @ Player {playerId, name} = do
  let json = VersionStamped.encodeWithVersion version player
  delegate playerId name json

findPlayerById :: GameJsonPersister -> String -> Result (Maybe Player)
findPlayerById GameJsonPersister {findPlayerById = delegate} playerId = do
  maybeJson <- delegate playerId
  return $ maybeJson >>= VersionStamped.decodeAndExtract

findPlayerByName :: GameJsonPersister -> String -> Result (Maybe Player)
findPlayerByName GameJsonPersister {findPlayerByName = delegate} playerName = do
  maybeJson <- delegate playerName
  return $ maybeJson >>= VersionStamped.decodeAndExtract

clearPlayers :: GameJsonPersister -> Result ()
clearPlayers GameJsonPersister {clearPlayers = delegate} = delegate

addGame :: GameJsonPersister -> Version -> GameData -> Result ()
addGame GameJsonPersister {addGame = delegate} version gameData @ GameData {base} = do
  let GameBase {gameId, playerId} = base
      json = VersionStamped.encodeWithVersion version gameData
  delegate gameId playerId json

updateGame :: GameJsonPersister -> Version -> GameData -> Result ()
updateGame GameJsonPersister {updateGame = delegate} version gameData @ GameData {base, plays} = do
  let GameBase {gameId} = base
      json = VersionStamped.encodeWithVersion version gameData
  delegate gameId json

findGameById :: GameJsonPersister -> String -> Result (Maybe GameData)
findGameById GameJsonPersister {findGameById = delegate} gameUid = do
  maybeJson <- delegate gameUid
  let maybeGameData = maybeJson >>= VersionStamped.decodeAndExtract
  return maybeGameData

deleteGame :: GameJsonPersister -> String -> Result ()
deleteGame GameJsonPersister {deleteGame = delegate} = delegate

clearGames :: GameJsonPersister -> Result ()
clearGames GameJsonPersister {clearGames = delegate} = delegate

mkBridge :: GameJsonPersister -> Version -> GamePersister
mkBridge jsonPersister version =
  GamePersister
    (migrate jsonPersister)
    (savePlayer jsonPersister version)
    (findPlayerById jsonPersister)
    (findPlayerByName jsonPersister)
    (clearPlayers jsonPersister)
    (addGame jsonPersister version)
    (updateGame jsonPersister version)
    (findGameById jsonPersister)
    (deleteGame jsonPersister)
    (clearGames jsonPersister)
