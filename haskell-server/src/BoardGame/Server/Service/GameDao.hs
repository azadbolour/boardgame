--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE EmptyDataDecls             #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ExistentialQuantification #-}

{-|
The data access layer for the board game application.
-}
module BoardGame.Server.Service.GameDao (
    GameRow(..)
  , PlayerRow(..)
  , PlayerRowId
  , PlayRow(..)
  , addGame
  , findGameRowIdById
  , findExistingGameRowIdByGameId
  , addPlayer
  , findPlayerRowIdByName
  , findExistingPlayerRowIdByName
  , addPlay
  , getGamePlays
  , cleanupDb
  , migrateDb
) where

import Control.Monad.Reader (asks)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Except (MonadError(..))

import Database.Esqueleto (
    Entity(..)
  , SqlExpr
  , select
  , from
  , insert
  , delete
  , where_
  -- , orderBy
  -- , desc
  , val
  , (==.)
  , (^.)
  )

import Database.Persist.Sql (
    ConnectionPool
  , SqlPersistT
  , SqlPersistM
  , fromSqlKey
  , runSqlPool
  )

import Database.Persist.TH
import BoardGame.Server.Domain.Core(EntityId)
import BoardGame.Server.Domain.GameError(GameError(..))
import Bolour.Grid.Point(Coordinate)
import BoardGame.Common.Domain.Player (PlayerName)
import qualified BoardGame.Server.Domain.GameEnv as GameEnv(GameEnv(..))

import Bolour.Util.PersistRunner (ConnectionProvider)
import qualified Bolour.Util.PersistRunner as PersistRunner

{-
  To see generated code:
  stack build --ghc-options="-ddump-splices -dsuppress-all"
  find .stack-work -name \*.dump-splices # It is under the dist directory.
-}

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
PlayerRow sql=player
    name String
    UniqueName name
    deriving Show Eq
GameRow sql=game
    gameUid String
    player PlayerRowId
    dimension Coordinate
    traySize Int
    UniqueGameUid gameUid
    deriving Show Eq
PlayRow sql=play
    game GameRowId
    number Int
    turn String
    isPlay Bool
    details String
    deriving Show Eq
|]

migration = migrateAll -- Generated.

migrateDb :: ConnectionProvider -> IO ()
migrateDb provider = PersistRunner.migrateDatabase provider migration

cleanupDb :: ConnectionProvider -> IO ()
cleanupDb provider = do
  PersistRunner.runQuery provider deleteAllPlaysReader
  PersistRunner.runQuery provider deleteAllGamesReader
  PersistRunner.runQuery provider deleteAllPlayersReader

-- TODO. Generic delete function??
deleteAllGamesReader :: SqlPersistM ()
deleteAllGamesReader =
  delete $
    from $ \(game :: SqlExpr (Entity GameRow)) ->
    return ()

deleteAllPlayersReader :: SqlPersistM ()
deleteAllPlayersReader =
  delete $
    from $ \(player :: SqlExpr (Entity PlayerRow)) ->
    return ()

deleteAllPlaysReader :: SqlPersistM ()
deleteAllPlaysReader =
  delete $
    from $ \(play :: SqlExpr (Entity PlayRow)) ->
    return ()

-- TODO. Should catch and translate any exceptions from persistent.

addPlayer :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> PlayerRow
  -> m EntityId
addPlayer provider player =
  liftIO $ PersistRunner.runQuery provider (addPlayerReader player)

addPlayerReader :: PlayerRow -> SqlPersistM EntityId
addPlayerReader player = fromSqlKey <$> insert player

addGame :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> GameRow
  -> m EntityId
addGame provider game =
  liftIO $ PersistRunner.runQuery provider (addGameReader game)

addGameReader :: GameRow -> SqlPersistM EntityId
addGameReader game = fromSqlKey <$> insert game

findExistingPlayerRowIdByName :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> PlayerName
  -> m PlayerRowId
findExistingPlayerRowIdByName provider playerName = do
  maybeRowId <- findPlayerRowIdByName provider playerName
  case maybeRowId of
    Nothing -> throwError $ MissingPlayerError playerName
    Just rowId -> return rowId

findPlayerRowIdByName :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> String
  -> m (Maybe PlayerRowId)
findPlayerRowIdByName provider playerName =
  liftIO $ PersistRunner.runQuery provider (findPlayerRowIdByNameReader playerName)

findPlayerRowIdByNameReader :: String -> SqlPersistM (Maybe PlayerRowId)
findPlayerRowIdByNameReader playerName = do
  selectedEntityList <- select $
    from $ \player -> do
      where_ (player ^. PlayerRowName ==. val playerName)
      return player
  case selectedEntityList of
    [] -> return Nothing
    Entity k _ : _ -> return $ Just k

addPlay :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> PlayRow
  -> m EntityId
addPlay provider play =
  liftIO $ PersistRunner.runQuery provider (addPlayReader play)

addPlayReader :: PlayRow -> SqlPersistM EntityId
addPlayReader play = fromSqlKey <$> insert play

findExistingGameRowIdByGameId :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> String
  -> m GameRowId
findExistingGameRowIdByGameId provider gameId = do
  maybeRowId <- findGameRowIdById provider gameId
  case maybeRowId of
    Nothing -> throwError $ MissingGameError gameId
    Just rowId -> return rowId

findGameRowIdById :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> String
  -> m (Maybe GameRowId)
findGameRowIdById provider gameUid =
  liftIO $ PersistRunner.runQuery provider (findGameRowIdByIdReader gameUid)

findGameRowIdByIdReader :: String -> SqlPersistM (Maybe GameRowId)
findGameRowIdByIdReader gameUid = do
  selectedEntityList <- select $
    from $ \game -> do
      where_ (game ^. GameRowGameUid ==. val gameUid)
      return game
  case selectedEntityList of
    [] -> return Nothing
    Entity k _ : _ -> return $ Just k

getGamePlays :: (MonadError GameError m, MonadIO m) =>
     ConnectionProvider
  -> String
  -> m [PlayRow]
getGamePlays provider gameUid = do
  maybeGameRowId <- findGameRowIdById provider gameUid
  case maybeGameRowId of
    Nothing -> throwError $ MissingGameError gameUid
    Just gameRowId ->
      liftIO $ PersistRunner.runQuery provider (getGamePlaysReader gameRowId)

getGamePlaysReader :: GameRowId -> SqlPersistM [PlayRow]
getGamePlaysReader gameRowId = do
  selectedEntityList <-
      select $
        from $ \play -> do
        where_ (play ^. PlayRowGame ==. val gameRowId)
        return play
  return $ entityVal <$> selectedEntityList




