--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Util.CompactStringSet (
    CompactStringSet(..)
  , mkCompactStringSet
  , insert
  , insertAll
  , contains
  ) where

import Data.Bits
import qualified Data.Map.Strict as Map
import qualified Data.List as List
import Data.Hashable
import qualified Data.List.Split as Split

-- | Space efficient implementation of set of small strings.
--   Packs a number of strings into a single bucket.
data CompactStringSet = CompactStringSet {
  buckets :: Map.Map Int String
}

mkCompactStringSet :: CompactStringSet
mkCompactStringSet = CompactStringSet Map.empty

-- TODO. Size of hash table should be an input parameter to mkCompactStringSet.

hashMask :: Int
hashMask = 0x8FFFF -- 589823

hashIt :: String -> Int
hashIt elem = hash elem .&. hashMask

delimiterChar :: Char
delimiterChar = '\0'

delimiter :: String
delimiter = [delimiterChar]

pack :: String -> String -> String
pack packedElems elem = packedElems ++ delimiter ++ elem

unpack :: String -> [String]
unpack = Split.splitOn delimiter

insert :: CompactStringSet -> String -> CompactStringSet
insert CompactStringSet { buckets } elem =
  let index = hashIt elem
      bucket = Map.lookup index buckets
      bucketPlus = case bucket of
        Nothing -> elem
        Just packedElems -> pack packedElems elem
      bucketsPlus = Map.insert index bucketPlus buckets
  in CompactStringSet bucketsPlus

contains :: CompactStringSet -> String -> Bool
contains CompactStringSet { buckets } elem =
    let index = hashIt elem
        bucket = Map.lookup index buckets
    in case bucket of
       Nothing -> False
       Just packedElems -> elem `List.elem` unpack packedElems

-- TODO. Insertion of bulk data uses too much memory.
-- For now unusable for masked words. To be diagnosed.
insertAll :: CompactStringSet -> [String] -> CompactStringSet
insertAll = List.foldl' insert








