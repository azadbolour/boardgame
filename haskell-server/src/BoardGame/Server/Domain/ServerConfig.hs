--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}

module BoardGame.Server.Domain.ServerConfig (
    DeployEnv(..)
  , ServerConfig(..)
  , defaultServerConfig
  , readServerConfig
  , getServerConfig
  , maxDictionaries
  , dictionaryMaxMaskedLetters
  ) where

import Data.Aeson (FromJSON, ToJSON, toJSON)
import GHC.Generics (Generic)
import qualified Data.Yaml as Yaml
import qualified Data.Yaml.Config as YamlConf

import Bolour.Util.DbConfig (DbConfig, DbConfig(DbConfig))
import qualified Bolour.Util.DbConfig as DbConfig

-- | The deployment environment of the application.
data DeployEnv = Dev | Test | Prod
    deriving (Eq, Show, Read, Generic)

instance FromJSON DeployEnv
instance ToJSON DeployEnv

-- | Maximum number of language dictionaries (different language codes that can be used).
maxDictionaries :: Int
maxDictionaries = 100

dictionaryMaxMaskedLetters :: Int
dictionaryMaxMaskedLetters = 3

-- | Configuration parameters of the application.
data ServerConfig = ServerConfig {
    deployEnv :: DeployEnv
  , serverPort :: Int
  , maxActiveGames :: Int
  , maxGameMinutes :: Int
  , dictionaryDir :: String
  , languageCodes :: [String]
  , dbConfig :: DbConfig
} deriving (Show, Generic)

instance FromJSON ServerConfig
instance ToJSON ServerConfig

defaultAppEnv = Dev
defaultGameServerPort = 6587
defaultMaxActiveGames = 100
defaultMaxGameMinutes = 30
defaultDictionaryDir = ""
defaultLanguageCodes = ["en"]

-- | Default configuration parameters of the application.
defaultServerConfig :: ServerConfig
defaultServerConfig = ServerConfig
  defaultAppEnv
  defaultGameServerPort
  defaultMaxActiveGames
  defaultMaxGameMinutes
  defaultDictionaryDir
  defaultLanguageCodes
  DbConfig.defaultPostgresDbConfig -- TODO. Use defaultDbConfig (in-memory) sqlite not postgres.


-- | Generic JSON-like representation of the default configuration.
defaultServerConfigObj :: Yaml.Value
defaultServerConfigObj = toJSON defaultServerConfig

-- | Read the configuration parameters from a configuration file
--   and use default values for parameters not present in the file.
readServerConfig :: String -> IO ServerConfig
readServerConfig configFilePath =
  YamlConf.loadYamlSettings [configFilePath] [defaultServerConfigObj] YamlConf.ignoreEnv

-- | Get the application's YAML configuration parameters. If the configuration
--   file is not given or a parameter is not present in the given file,
--   the default value of the parameter is returned.
getServerConfig :: Maybe String -> IO ServerConfig
getServerConfig maybeConfigFilePath =
  case maybeConfigFilePath of
     Nothing -> return defaultServerConfig
     Just path -> readServerConfig path
