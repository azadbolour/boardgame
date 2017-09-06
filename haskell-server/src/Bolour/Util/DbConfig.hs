
--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Util.DbConfig (
    DbmsType(..)
  , DbConfig(..)
  , defaultDbConfig
  , defaultPostgresDbConfig
  , isInMemoryType
  , isInMemory
  ) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)

-- | Identifier of the database management system.
data DbmsType = SqliteMemory | Postgres
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

defaultDbHost="localhost"
defaultPostgresPort=5432
defaultPostgresDbName="postgres"
defaultPostgresDbUser = "postgres"
defaultPostgresDbPassword = "postgres"

defaultDbConfig = DbConfig SqliteMemory "" 0 "" "" ""
defaultPostgresDbConfig = DbConfig
  Postgres
  defaultDbHost
  defaultPostgresPort
  defaultPostgresDbName
  defaultPostgresDbUser
  defaultPostgresDbPassword

-- TODO. Default db name, user, and password should be independent of database.

isInMemoryType :: DbmsType -> Bool
isInMemoryType dbmsType =
  case dbmsType of
  SqliteMemory -> True
  Postgres -> False

isInMemory :: DbConfig -> Bool
isInMemory DbConfig {dbmsType} = isInMemoryType dbmsType