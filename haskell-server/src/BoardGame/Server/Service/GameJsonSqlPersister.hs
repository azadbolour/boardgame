--
-- Copyright 2017-2018 Azad Bolour
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
module BoardGame.Server.Service.GameJsonSqlPersister (
    migrateDb
  , mkPersister
) where

import Data.Maybe (listToMaybe, isJust)

import Control.Monad (unless)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except (throwE)

import Database.Esqueleto (
    Entity(..)
  , SqlExpr
  , select
  , from
  , insert
  , delete
  , where_
  , update
  , set
  -- , orderBy
  -- , desc
  , val
  , unValue
  , (==.)
  , (=.)
  , (^.)
  )

import Database.Persist.Sql (
    -- ConnectionPool
  -- , SqlPersistT
  SqlPersistM
  , fromSqlKey
  -- , runSqlPool
  )
import qualified Database.Persist.Sql as PersistSql (update, (=.))

import Database.Persist.TH
import Bolour.Util.Core (EntityId)
import BoardGame.Server.Domain.GameError(GameError(..))
import qualified BoardGame.Server.Domain.GameEnv as GameEnv(GameEnv(..))

import BoardGame.Server.Service.TypeDefs
import BoardGame.Server.Service.GameJsonPersister (GameJsonPersister, GameJsonPersister(GameJsonPersister))

import Bolour.Util.PersistRunner (ConnectionProvider)
import qualified Bolour.Util.PersistRunner as PersistRunner

{-
  To see generated code:
  stack build --ghc-options="-ddump-splices -dsuppress-all"
  find .stack-work -name \*.dump-splices # It is under the dist directory.
-}

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
PlayerRow sql=player
    playerUid String
    name String
    json String
    UniquePlayerUid playerUid
    UniqueName name
    deriving Show Eq
GameRow sql=game
    gameUid String
    playerUid String
    json String
    playerId PlayerRowId
    UniqueGameUid gameUid
    deriving Show Eq
|]


playerToRow :: PlayerId -> String -> JsonEncoded -> PlayerRow
playerToRow = PlayerRow

gameToRow :: GameId -> PlayerId -> String -> PlayerRowId -> GameRow
gameToRow = GameRow

migration = migrateAll -- Generated.

migrateDb :: ConnectionProvider -> IO ()
migrateDb provider =
  PersistRunner.migrateDatabase provider migration

-- TODO. Should just have one migrate!

migrate :: ConnectionProvider -> Result ()
migrate provider =
  liftIO $ migrateDb provider

addPlayer :: ConnectionProvider -> PlayerId -> String -> JsonEncoded -> Result ()
addPlayer provider playerId playerName json = do
  let row = PlayerRow playerId playerName json
  liftIO $ PersistRunner.runQuery provider (savePlayerReader row)
  return ()

savePlayerReader :: PlayerRow -> SqlPersistM EntityId
savePlayerReader row = fromSqlKey <$> insert row

findPlayerByName :: ConnectionProvider -> String -> Result (Maybe JsonEncoded)
findPlayerByName provider playerName =
  liftIO $ PersistRunner.runQuery provider (findPlayerByNameReader playerName)

findPlayerByNameReader :: String -> SqlPersistM (Maybe JsonEncoded)
findPlayerByNameReader playerName = do
  selectedList <- select $
    from $ \player -> do
      where_ (player ^. PlayerRowName ==. val playerName)
      return $ player ^. PlayerRowJson
  let maybeValue = listToMaybe selectedList
  return $ unValue <$> maybeValue

findPlayerById :: ConnectionProvider -> String -> Result (Maybe JsonEncoded)
findPlayerById provider playerUid =
  liftIO $ PersistRunner.runQuery provider (findPlayerByIdReader playerUid)

findPlayerByIdReader :: String -> SqlPersistM (Maybe JsonEncoded)
findPlayerByIdReader playerUid = do
  selectedList <- select $
    from $ \player -> do
      where_ (player ^. PlayerRowPlayerUid ==. val playerUid)
      return $ player ^. PlayerRowJson
  let maybeValue = listToMaybe selectedList
  return $ unValue <$> maybeValue

-- TODO. Use findPlayerById. Remove duplicate code.
findPlayerRowIdById :: ConnectionProvider -> String -> Result (Maybe PlayerRowId)
findPlayerRowIdById provider playerUid =
  liftIO $ PersistRunner.runQuery provider (findPlayerRowIdByIdReader playerUid)

findPlayerRowIdByIdReader :: String -> SqlPersistM (Maybe PlayerRowId)
findPlayerRowIdByIdReader playerUid = do
  selectedEntityList <- select $
    from $ \player -> do
      where_ (player ^. PlayerRowPlayerUid ==. val playerUid)
      return player
  case selectedEntityList of
    [] -> return Nothing
    Entity k _ : _ -> return $ Just k

clearPlayers :: ConnectionProvider -> Result ()
clearPlayers provider =
  liftIO $ PersistRunner.runQuery provider clearPlayersReader

-- TODO. Generic truncate function. Use variable for Row?

clearPlayersReader :: SqlPersistM ()
clearPlayersReader =
  delete $
    from $ \(player :: SqlExpr (Entity PlayerRow)) ->
    return ()

addGame :: ConnectionProvider -> GameId -> PlayerId -> JsonEncoded -> Result ()
addGame provider gameUid playerUid json = do
  maybePlayerRowId <- findPlayerRowIdById provider playerUid
  case maybePlayerRowId of
    Nothing -> throwE $ MissingPlayerError playerUid -- TODO. Should be MissingPlayerIdError
    Just playerRowId -> do
      let row = GameRow gameUid playerUid json playerRowId
      liftIO $ PersistRunner.runQuery provider (addGameReader row)
      return ()

-- TODO. Generic insert?
addGameReader :: GameRow -> SqlPersistM EntityId
addGameReader row = fromSqlKey <$> insert row

updateGame :: ConnectionProvider -> GameId -> JsonEncoded -> Result ()
updateGame provider gameUid json = do
  maybeEntity <- liftIO $ PersistRunner.runQuery provider (findGameByIdReader gameUid)
  unless (isJust maybeEntity) $ throwE $ MissingGameError gameUid
  return ()

updateGameReader :: GameId -> JsonEncoded -> SqlPersistM ()
updateGameReader gameUid json =
  update $ \game -> do
    set game [ GameRowJson =. val json ]
    where_ (game ^. GameRowGameUid ==. val gameUid)

findGameById :: ConnectionProvider -> GameId -> Result (Maybe JsonEncoded)
findGameById provider gameUid = do
  maybeEntity <- liftIO $ PersistRunner.runQuery provider (findGameByIdReader gameUid)
  let extractJson entity = case entityVal entity of
                             GameRow _ _ json _ -> json
  return $ extractJson <$> maybeEntity

findGameByIdReader :: String -> SqlPersistM (Maybe (Entity GameRow))
findGameByIdReader gameUid = do
  selectedList <- select $
    from $ \game -> do
      where_ (game ^. GameRowGameUid ==. val gameUid)
      return game
  let maybeEntity = listToMaybe selectedList
  return maybeEntity

deleteGame :: ConnectionProvider -> GameId -> Result ()
deleteGame provider gameUid =
  liftIO $ PersistRunner.runQuery provider (deleteGameReader gameUid)

deleteGameReader :: GameId -> SqlPersistM ()
deleteGameReader gameUid =
  delete $
    from $ \(game :: SqlExpr (Entity GameRow)) -> do
    where_ (game ^. GameRowGameUid ==. val gameUid)
    return ()

clearGames :: ConnectionProvider -> Result ()
clearGames provider =
  liftIO $ PersistRunner.runQuery provider clearGamesReader

clearGamesReader :: SqlPersistM ()
clearGamesReader =
  delete $
    from $ \(game :: SqlExpr (Entity GameRow)) ->
    return ()

mkPersister :: ConnectionProvider -> GameJsonPersister
mkPersister provider =
  GameJsonPersister
    (migrate provider)
    (addPlayer provider)
    (findPlayerById provider)
    (findPlayerByName provider)
    (clearPlayers provider)
    (addGame provider)
    (updateGame provider)
    (findGameById provider)
    (deleteGame provider)
    (clearGames provider)
