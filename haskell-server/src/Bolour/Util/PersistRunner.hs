--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Bolour.Util.PersistRunner (
    ConnectionProvider
  , mkConnectionProvider
  , runQuery
  , migrateDatabase
  )
  where

import Data.Text as Text (pack)
import Data.ByteString.Char8 as BS (pack)
import Data.String.Here.Interpolated (iTrim)
import Control.Monad.Logger (runStdoutLoggingT)

import Database.Persist.Sql (
    ConnectionPool
  , SqlPersistT
  , SqlPersistM
  , Migration
  , runSqlPersistMPool
  , runSqlPool
  , runMigration
  )

import Database.Persist.Sqlite (
      runSqlite
    , createSqlitePool
  )

import Database.Persist.Postgresql (
    ConnectionString
  , createPostgresqlPool
  )

import Bolour.Util.DbConfig (DbConfig, DbConfig(DbConfig), DbmsType)
import qualified Bolour.Util.DbConfig as DbConfig

-- | Using a generic type name to be able to extend this type if necessary for other databases
--   or database access packages.
type ConnectionProvider = ConnectionPool

poolCapacity = 20

mkConnectionProvider :: DbConfig -> IO ConnectionProvider
mkConnectionProvider dbConfig @ DbConfig {dbmsType} =
  case dbmsType of
  DbConfig.Sqlite -> mkSqlitePool dbConfig
  DbConfig.Postgres -> mkPostgresPool dbConfig

-- | Run a database query. TODO. Extent runQuery to include other databases.
--   Rather than Maybe ConnectionPool may have to pass other information.
runQuery ::
  ConnectionProvider
  -> SqlPersistM result  -- ^ The query.
  -> IO result           -- ^ The query as a reader of a sql backend.
runQuery pool backendReader = runSqlPersistMPool backendReader pool

migrateDatabase :: ConnectionProvider -> Migration -> IO ()
migrateDatabase pool migration = runSqlPool (runMigration migration) pool

mkSqlitePool :: DbConfig -> IO ConnectionPool
mkSqlitePool dbConfig @ DbConfig {dbName} = do
  let capacity = poolCapacity
  runStdoutLoggingT $ createSqlitePool (Text.pack dbName) capacity

mkPostgresPool :: DbConfig -> IO ConnectionPool
mkPostgresPool dbConfig = do
  let connectionString = mkPostgresConnectionString dbConfig
  let capacity = 10
  runStdoutLoggingT $ createPostgresqlPool connectionString capacity

mkPostgresConnectionString :: DbConfig -> ConnectionString
mkPostgresConnectionString DbConfig {dbHost, dbPort, dbName, dbUser, dbPassword} = BS.pack cs where
  cs = [iTrim|host=${dbHost} port=${dbPort} user=${dbUser} password=${dbPassword} dbname=${dbName}|]





