--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Bolour.Util.VersionStamped (
    Version
  , VersionStamped(..)
  , encode, decode
  , encodeWithVersion, decodeAndExtract
)
where

import GHC.Generics
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Lazy.Char8 as BC

type Version = Int

data VersionStamped v = VersionStamped {
    version :: Version
  , value :: v
}
  deriving (Eq, Show, Generic)

instance (FromJSON v) => FromJSON (VersionStamped v)
instance (ToJSON v) => ToJSON (VersionStamped v)

encode :: ToJSON v => VersionStamped v -> String
encode stamped = BC.unpack $ Aeson.encode stamped

decode :: FromJSON v => String -> Maybe (VersionStamped v)
decode encoded = Aeson.decode $ BC.pack encoded

encodeWithVersion :: ToJSON v => Version -> v -> String
encodeWithVersion version value = encode $ VersionStamped version value

decodeAndExtract :: FromJSON v => String -> Maybe v
decodeAndExtract encoded = value <$> decode encoded
