
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module TempTrial where

import qualified Data.Maybe as Maybe

import qualified Data.Text as Text
import Data.ByteString.Lazy.Char8 as BS

import qualified Data.HashMap.Strict as HashMap

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson
import Data.Aeson (encode, decode, toJSON, Value, Value(Object))

import BoardGame.Server.Domain.GameError (GameError(..))
import qualified BoardGame.Server.Domain.GameError as GameError

main :: IO ()

main = do
  let encoded = GameError.encodeGameErrorWithMessage $ GameTimedOutError "000000" 20
  print encoded
  let encoded' = GameError.encodeGameErrorWithMessage $ InternalError "ERRRRR"
  print encoded'
  print "OK"

