--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE QuasiQuotes #-}

module Bolour.Util.EnvUtil (
    lookupSetting
) where

import Data.String.Here.Interpolated (iTrim)
import System.Environment (lookupEnv)
import Safe (readMay)

-- | Look up an environment variable.
lookupSetting :: Read a =>
  String      -- ^ The name of the env variable.
  -> a        -- ^ The default value if the env variable is not defined.
  -> IO a     -- ^ The value wrapped in IO (since obtained externally).
lookupSetting envVar defaultVal = do
    maybeValue <- lookupEnv envVar
    case maybeValue of
        Nothing ->
            return defaultVal
        Just str ->
            maybe (handleFailedRead str) return (readMay str)
            where
                handleFailedRead =
                    error $ [iTrim|failed to read environment variable '${envVar}'|]



