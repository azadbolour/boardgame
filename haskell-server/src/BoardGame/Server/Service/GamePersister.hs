--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.GamePersister (
    GamePersister(..)
  , saveGame
  , clearAllData
) where

import Control.Monad (unless)
import Control.Monad.Trans.Except (throwE)

import BoardGame.Server.Service.TypeDefs (Result)
import BoardGame.Server.Domain.Player (Player)
import BoardGame.Server.Service.GameData (GameData)
import BoardGame.Server.Domain.GameError (GameError(InternalError), GameError(MissingPlayerError))
import BoardGame.Server.Domain.Player (Player, Player(Player))
import qualified BoardGame.Server.Domain.Player as Player
import BoardGame.Server.Domain.GameBase (GameBase, GameBase(GameBase))
import qualified BoardGame.Server.Domain.GameBase as GameBase
import BoardGame.Server.Service.GameData (GameData, GameData(GameData))
import qualified BoardGame.Server.Service.GameData as GameData

data GamePersister = GamePersister {
    migrate :: Result ()
  , addPlayer :: Player -> Result ()
  , findPlayerById :: String -> Result (Maybe Player)
  , findPlayerByName :: String -> Result (Maybe Player)
  , clearPlayers :: Result ()
  , addGame :: GameData -> Result ()
  , updateGame :: GameData -> Result ()
  , findGameById :: String -> Result (Maybe GameData)
  , deleteGame :: String -> Result ()
  , clearGames :: Result ()
}

saveGame :: GamePersister -> GameData -> Result ()
saveGame persister @ GamePersister {findPlayerById} gameData @ GameData {base} = do
  let GameBase {gameId, playerId} = base
  maybePlayer <- findPlayerById playerId
  case maybePlayer of
    Nothing -> throwE $ MissingPlayerError playerId -- TODO. Should be MissingPlayerIdError.
    Just player @ Player {playerId, name} ->
      addOrUpdateGame persister gameData

addOrUpdateGame :: GamePersister -> GameData -> Result ()
addOrUpdateGame GamePersister {findGameById, addGame, updateGame} gameData @ GameData {base} = do
  let GameBase {gameId} = base
  maybeGame <- findGameById gameId
  case maybeGame of
    Nothing -> addGame gameData
    _ -> updateGame gameData

clearAllData :: GamePersister -> Result ()
clearAllData GamePersister {clearPlayers, clearGames} = do
  clearGames
  clearPlayers


