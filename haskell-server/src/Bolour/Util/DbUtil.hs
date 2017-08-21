--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module Bolour.Util.DbUtil (
      makePool
    , queryInIO
    , SqlBackendReader
  )where

-- import System.Environment (lookupEnv)
import qualified Data.ByteString.Char8 as BS
import Data.String.Here.Interpolated (iTrim)
-- import Control.Exception (throwIO)
import Control.Monad.Logger (
    -- MonadLogger
    NoLoggingT
  -- , runNoLoggingT
  , runStdoutLoggingT
  )
-- import Control.Monad.Reader (MonadIO)
-- import Control.Monad.Trans.Control (MonadBaseControl)
-- import Control.Monad.Trans.Maybe (MaybeT (..), runMaybeT)
import Control.Monad.Trans.Reader (ReaderT)
import Control.Monad.Trans.Resource (ResourceT)
import Database.Persist.Sql (SqlBackend)
import Database.Persist.Postgresql (
    ConnectionPool
  , ConnectionString
  , createPostgresqlPool
  , runSqlPersistMPool
  )
import BoardGame.Server.Domain.GameConfig (Config, DeployEnv)
import BoardGame.Server.Domain.GameConfig (ServerParameters(ServerParameters))
import qualified BoardGame.Server.Domain.GameConfig as Config
import qualified BoardGame.Server.Domain.GameConfig as Env
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters

type SqlBackendReader result = ReaderT SqlBackend (NoLoggingT (ResourceT IO)) result

-- TODO. What types of exceptions may be thrown by Persistent.
-- TODO. Best practices for catching db access errors from Persistent and Esqueleto.
-- TODO. Create test for non-existent database.

-- TODO. Add additional db parameters to server parameters.
dbHost :: String
dbHost="localhost"
dbPort :: Int
dbPort=5432
dbName :: String
dbName="postgres"

-- | Make a connection pool for accessing the database
--   associated with a given execution environment.
makePool :: ServerParameters -> IO ConnectionPool
makePool (serverParameters @ ServerParameters.ServerParameters {deployEnv}) = do
  let connectionString = mkConnectionString serverParameters
  let capacity = numConnections deployEnv
  runStdoutLoggingT $ createPostgresqlPool connectionString capacity

mkConnectionString :: ServerParameters -> ConnectionString
mkConnectionString ServerParameters.ServerParameters {dbUser, dbPassword} = BS.pack cs where
  cs = [iTrim|host=${dbHost} port=${dbPort} user=${dbUser} password=${dbPassword} dbname=${dbName}|]

-- | Number of connections to use in a connection pool for each execution environment.
numConnections :: DeployEnv -> Int
numConnections Env.Test = 1
numConnections Env.Dev = 1
numConnections Env.Prod = 8

-- | Run a database query.
queryInIO ::
  Config                      -- ^ Includes the connection pool to use.
  -> SqlBackendReader result  -- ^ The query.
  -> IO result                -- ^ The query as a reader of a sql backend.
queryInIO config backendReader = runSqlPersistMPool backendReader (Config.pool config)

