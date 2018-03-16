--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.HttpUtil (
    mkHttpHeader
  , defaultOptionsHeaders
)
  where

import qualified Data.CaseInsensitive as CI
import qualified Data.ByteString.Char8 as BC
import Network.HTTP.Types.Header (Header, ResponseHeaders)

-- | Headers for response to options request.
defaultOptionsHeaders :: ResponseHeaders
defaultOptionsHeaders = mkHttpResponseHeaders [
      ("Access-Control-Allow-Origin", "*")
    , ("Access-Control-Allow-Headers", "authorization")
    , ("Access-Control-Allow-Headers", "credentials")
    , ("Access-Control-Allow-Headers", "mode")
    , ("Access-Control-Allow-Headers", "accept")
    , ("Access-Control-Allow-Headers", "content-type")
  ]

-- | Convert headers represented as string name-value pairs to header data structures.
mkHttpResponseHeaders :: [(String, String)] -> ResponseHeaders
mkHttpResponseHeaders stringHeaderList = mkHttpHeader <$> stringHeaderList

-- | Convert a header represented as a string name-value pair to a header data structure.
mkHttpHeader :: (String, String) -> Header
mkHttpHeader (name, value) = (CI.mk $ BC.pack name, BC.pack value)


