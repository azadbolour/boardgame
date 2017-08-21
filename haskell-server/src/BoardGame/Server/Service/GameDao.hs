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

{-|
The data access layer for the board game application.
-}
module BoardGame.Server.Service.GameDao (
    GameRow(..)
  , PlayerRow(..)
  , PlayerRowId
  , PlayRow(..)
  , migrateDatabase
  , addGame
  , findGameRowIdById
  , findExistingGameRowIdByGameId
  , addPlayer
  , findPlayerRowIdByName
  , findExistingPlayerRowIdByName
  , addPlay
  , getGamePlays
  , cleanupDb
) where

import Control.Monad.Reader (asks)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Except (MonadError(..))

import Database.Persist.Postgresql (ConnectionPool)

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
import Database.Persist.Postgresql (
    runSqlPool
  , fromSqlKey
  , runMigration
  -- , entityVal
  , SqlPersistT
  )
import Database.Persist.TH
import BoardGame.Server.Domain.GameConfig
import Bolour.Util.DbUtil (SqlBackendReader, queryInIO)
import BoardGame.Server.Domain.Core(EntityId)
import BoardGame.Server.Domain.GameError(GameError(..))
import BoardGame.Common.Domain.Point(Coordinate)
import BoardGame.Common.Domain.Player (PlayerName)
import BoardGame.Server.Service.GameTransformerStack(GameTransformerStack)
import qualified BoardGame.Server.Domain.GameEnv as GameEnv(GameEnv(..))

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
    height Coordinate
    width Coordinate
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

-- Move generic part of this to DbUtil.

migrateDatabase :: ConnectionPool -> IO ()
migrateDatabase pool = runSqlPool doMigrations pool

doMigrations :: SqlPersistT IO ()
doMigrations = runMigration migrateAll

cleanupDb :: Config -> IO ()
cleanupDb config = do
  queryInIO config deleteAllPlaysReader
  queryInIO config deleteAllGamesReader
  queryInIO config deleteAllPlayersReader

-- TODO. Generic delete function??
deleteAllGamesReader :: SqlBackendReader ()
deleteAllGamesReader =
  delete $
    from $ \(game :: SqlExpr (Entity GameRow)) ->
    return ()

deleteAllPlayersReader :: SqlBackendReader ()
deleteAllPlayersReader =
  delete $
    from $ \(player :: SqlExpr (Entity PlayerRow)) ->
    return ()

deleteAllPlaysReader :: SqlBackendReader ()
deleteAllPlaysReader =
  delete $
    from $ \(play :: SqlExpr (Entity PlayRow)) ->
    return ()

-- TODO. Should catch and translate any exceptions from persistent.

addPlayer :: PlayerRow -> GameTransformerStack EntityId
addPlayer player = do
  cfg <- asks GameEnv.config
  liftIO $ queryInIO cfg (addPlayerReader player)

addPlayerReader :: PlayerRow -> SqlBackendReader EntityId
addPlayerReader player = fromSqlKey <$> insert player

addGame :: GameRow -> GameTransformerStack EntityId
addGame game = do
  cfg <- asks GameEnv.config
  liftIO $ queryInIO cfg (addGameReader game)

addGameReader :: GameRow -> SqlBackendReader EntityId
addGameReader game = fromSqlKey <$> insert game

findExistingPlayerRowIdByName :: PlayerName -> GameTransformerStack PlayerRowId
findExistingPlayerRowIdByName playerName = do
  maybeRowId <- findPlayerRowIdByName playerName
  case maybeRowId of
    Nothing -> throwError $ MissingPlayerError playerName
    Just rowId -> return rowId

findPlayerRowIdByName :: String -> GameTransformerStack (Maybe PlayerRowId)
findPlayerRowIdByName playerName = do
  cfg <- asks GameEnv.config
  liftIO $ queryInIO cfg (findPlayerRowIdByNameReader playerName)

findPlayerRowIdByNameReader :: String -> SqlBackendReader (Maybe PlayerRowId)
findPlayerRowIdByNameReader playerName = do
  selectedEntityList <- select $
    from $ \player -> do
      where_ (player ^. PlayerRowName ==. val playerName)
      return player
  case selectedEntityList of
    [] -> return Nothing
    Entity k _ : _ -> return $ Just $ k

addPlay :: PlayRow -> GameTransformerStack EntityId
addPlay play = do
  cfg <- asks GameEnv.config
  liftIO $ queryInIO cfg (addPlayReader play)

addPlayReader :: PlayRow -> SqlBackendReader EntityId
addPlayReader play = fromSqlKey <$> insert play

findExistingGameRowIdByGameId :: String -> GameTransformerStack GameRowId
findExistingGameRowIdByGameId gameId = do
  maybeRowId <- findGameRowIdById gameId
  case maybeRowId of
    Nothing -> throwError $ MissingGameError gameId
    Just rowId -> return rowId

findGameRowIdById :: String -> GameTransformerStack (Maybe GameRowId)
findGameRowIdById gameUid = do
  cfg <- asks GameEnv.config
  liftIO $ queryInIO cfg (findGameRowIdByIdReader gameUid)

findGameRowIdByIdReader :: String -> SqlBackendReader (Maybe GameRowId)
findGameRowIdByIdReader gameUid = do
  selectedEntityList <- select $
    from $ \game -> do
      where_ (game ^. GameRowGameUid ==. val gameUid)
      return game
  case selectedEntityList of
    [] -> return Nothing
    Entity k _ : _ -> return $ Just $ k

getGamePlays :: String -> GameTransformerStack [PlayRow]
getGamePlays gameUid = do
  maybeGameRowId <- findGameRowIdById gameUid
  case maybeGameRowId of
    Nothing -> throwError $ MissingGameError gameUid
    Just gameRowId -> do
      cfg <- asks GameEnv.config
      liftIO $ queryInIO cfg (getGamePlaysReader gameRowId)

getGamePlaysReader :: GameRowId -> SqlBackendReader [PlayRow]
getGamePlaysReader gameRowId = do
  selectedEntityList <-
      select $
        from $ \play -> do
        where_ (play ^. PlayRowGame ==. val gameRowId)
        return play
  return $ entityVal <$> selectedEntityList




