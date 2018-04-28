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
) where

import Data.Maybe (listToMaybe)

-- import Control.Monad.Reader (asks)
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
  -- , orderBy
  -- , desc
  , val
  , unValue
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
migrateDb provider = PersistRunner.migrateDatabase provider migration

-- TODO. Should just have one migrate!

migrate :: ConnectionProvider -> Result ()
migrate provider =
  return ()

savePlayer :: ConnectionProvider -> PlayerId -> String -> JsonEncoded -> Result ()
savePlayer provider playerId playerName json = do
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

saveGame :: ConnectionProvider -> GameId -> PlayerId -> JsonEncoded -> Result ()
saveGame provider gameUid playerUid json = do
  maybePlayerRowId <- findPlayerRowIdById provider playerUid
  case maybePlayerRowId of
    Nothing -> throwE $ MissingPlayerError gameUid -- TODO. Should be player name!
    Just playerRowId -> do
      let row = GameRow gameUid playerUid json playerRowId
      liftIO $ PersistRunner.runQuery provider (saveGameReader row)
      return ()

-- TODO. Generic insert?
saveGameReader :: GameRow -> SqlPersistM EntityId
saveGameReader row = fromSqlKey <$> insert row

findGameById :: ConnectionProvider -> GameId -> Result (Maybe JsonEncoded)
findGameById provider gameUid =
  liftIO $ PersistRunner.runQuery provider (findGameByIdReader gameUid)

findGameByIdReader :: String -> SqlPersistM (Maybe JsonEncoded)
findGameByIdReader gameUid = do
  selectedList <- select $
    from $ \game -> do
      where_ (game ^. GameRowGameUid ==. val gameUid)
      return $ game ^. GameRowJson
  let maybeValue = listToMaybe selectedList
  return $ unValue <$> maybeValue

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
    (savePlayer provider)
    (findPlayerByName provider)
    (clearPlayers provider)
    (saveGame provider)
    (findGameById provider)
    (deleteGame provider)
    (clearGames provider)
