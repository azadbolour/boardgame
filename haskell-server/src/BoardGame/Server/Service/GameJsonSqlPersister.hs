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

-- import Control.Monad.Reader (asks)
import Control.Monad.IO.Class (liftIO)
-- import Control.Monad.Except (MonadError(..))

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

migrate :: ConnectionProvider -> Result ()
migrate provider =
  return ()

savePlayer :: ConnectionProvider -> PlayerId -> String -> JsonEncoded -> Result ()
savePlayer provider playerId playerName json = do
  let row = PlayerRow playerId playerName json
  liftIO $ PersistRunner.runQuery provider (addPlayerReader row)
  return ()

addPlayerReader :: PlayerRow -> SqlPersistM EntityId
addPlayerReader row = fromSqlKey <$> insert row

findPlayerByName :: ConnectionProvider -> String -> Result (Maybe JsonEncoded)
findPlayerByName provider playerName =
  return Nothing

clearPlayers :: ConnectionProvider -> Result ()
clearPlayers provider =
  return ()

saveGame :: ConnectionProvider -> GameId -> PlayerId -> JsonEncoded -> Result ()
saveGame provider gameId playerId json =
  return ()

findGameById :: ConnectionProvider -> GameId -> Result (Maybe JsonEncoded)
findGameById provider gameId =
  return Nothing

deleteGame :: ConnectionProvider -> GameId -> Result ()
deleteGame provider gameId =
  return ()

clearGames :: ConnectionProvider -> Result ()
clearGames provider =
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






