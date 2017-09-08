
--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

{-
  Note about in-memory sqlite.

  In Sqlite, the in-memory database has the name ':memory:'. With an
  in-memory database, the simple model is that there is a single connection
  and once that connection goes away the database is dropped.

  Our application of course requires repeated independent interactions with
  the database from different threads, which means that one of more connections
  to the in-memory database must stay open throughout the application so it is
  not dropped.

  But I have not yet found a way to get a reference to something that represents
  a connection to an in-memory Sqlite database from the Haskell Persistent interface.

  All the examples I have seen for in-memory database interactions use the runSqlite
  function. It appears that once runSqlite returns it closes the connection to
  the in-memory database and so the database is dropped.

  So event though in-memory Sqlite is the preferred database for tests, I am
  not sure how to make that work with Persistent. For now, we'll just forget
  about in-memory Sqlite and use durable Sqlite only.

  There is a note in Database.Persist.Sqlite that says to use withSqliteConn
  to avoid such issues caused by pools. That may be the solution to our issue.
  But for now I am out of my time-box on this.

  TODO. Pursue memory sqlite for testing.
-}

module Bolour.Util.DbConfig (
    DbmsType(..)
  , DbConfig(..)
  , defaultDbConfig
  , defaultPostgresDbConfig
  ) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)

-- | Identifier of the database management system.
data DbmsType = Sqlite | Postgres
  deriving (Eq, Show, Read, Generic)

instance FromJSON DbmsType
instance ToJSON DbmsType

-- | Connection parameters.
data DbConfig = DbConfig {
    dbmsType :: DbmsType
  , dbHost :: String
  , dbPort :: Int
  , dbName :: String
  , dbUser :: String
  , dbPassword :: String
} deriving (Show, Generic)

instance FromJSON DbConfig
instance ToJSON DbConfig

defaultDbHost = "localhost"
defaultPostgresPort = 5432
defaultPostgresDbName = "postgres"
defaultPostgresDbUser = "postgres"
defaultPostgresDbPassword = "postgres"

defaultSqliteDbName = "game-sqlite.db"

defaultSqliteConfig = DbConfig Sqlite "" 0 defaultSqliteDbName "" ""

defaultPostgresDbConfig = DbConfig
  Postgres
  defaultDbHost
  defaultPostgresPort
  defaultPostgresDbName
  defaultPostgresDbUser
  defaultPostgresDbPassword

defaultDbConfig = defaultSqliteConfig

sqliteMemoryDbName = ":memory:"

-- TODO. Default db name, user, and password should be independent of database.
