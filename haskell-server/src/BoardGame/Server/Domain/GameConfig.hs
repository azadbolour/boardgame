--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}

module BoardGame.Server.Domain.GameConfig (
    DeployEnv(..)
  , ServerParameters(..)
  , Config(..)
  , mkConfig
  , getServerParameters
  , defaultServerParameters
) where

import qualified Data.Yaml as Yaml
import qualified Data.Yaml.Config as YamlConf
import Data.Aeson (FromJSON, ToJSON, toJSON)
import GHC.Generics (Generic)

import Database.Persist.Postgresql (ConnectionPool)

-- | The deployment environment of the application.
data DeployEnv = Dev | Test | Prod
    deriving (Eq, Show, Read, Generic)

instance FromJSON DeployEnv
instance ToJSON DeployEnv

-- appEnvName = "BOARD_GAME_APP_ENV"
-- maxActiveGamesName = "MAX_ACTIVE_GAMES"
-- maxGameMinutesName = "MAX_GAME_MINUTES"
-- gameServerPortName = "GAME_SERVER_PORT"
-- dictionaryDirName = "DICTIONARY_DIR"

defaultAppEnv = Dev
defaultGameServerPort = 6587
defaultDbUser = "postgres"
defaultDbPassword = "postgres"
defaultMaxActiveGames = 100
defaultMaxGameMinutes = 30
defaultDictionaryDir = "" -- Default is computed in dictionary module.

-- TODO. Rename to GameConfig.
-- | Complete configuration of the application.
data Config = Config {
    serverParameters :: ServerParameters
  , pool :: ConnectionPool
}

mkConfig :: ServerParameters -> ConnectionPool -> IO Config
mkConfig serverParameters pool = return $ Config serverParameters pool

-- TODO. Add dbName, dbHost, dbPort.

-- | Configuration parameters of the application.
data ServerParameters = ServerParameters {
    deployEnv :: DeployEnv
  , serverPort :: Int
  , dbUser :: String
  , dbPassword :: String
  , maxActiveGames :: Int
  , maxGameMinutes :: Int
  , dictionaryDir :: String
} deriving (Show, Generic)

instance FromJSON ServerParameters
instance ToJSON ServerParameters

-- | Default configuration parameters of the application.
defaultServerParameters :: ServerParameters
defaultServerParameters = ServerParameters
  defaultAppEnv
  defaultGameServerPort
  defaultDbUser
  defaultDbPassword
  defaultMaxActiveGames
  defaultMaxGameMinutes
  defaultDictionaryDir

-- | Generic JSON-like representation of the default configuration.
defaultServerParametersObj :: Yaml.Value
defaultServerParametersObj = toJSON defaultServerParameters

-- | Read the configuration parameters from a configuration file
--   and use default values for parameters not present in the file.
readServerParameters :: String -> IO ServerParameters
readServerParameters configFilePath =
  YamlConf.loadYamlSettings [configFilePath] [defaultServerParametersObj] YamlConf.ignoreEnv

-- | Get the application's YAML configuration parameters. If the configuration
--   file is not given or a parameter is not present in the given file,
--   the default value of the parameter is returned.
getServerParameters :: Maybe String -> IO ServerParameters
getServerParameters maybeConfigFilePath =
  case maybeConfigFilePath of
     Nothing -> return defaultServerParameters
     Just path -> readServerParameters path







