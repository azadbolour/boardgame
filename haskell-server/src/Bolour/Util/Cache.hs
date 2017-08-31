--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module Bolour.Util.Cache (
    Cache
  , Cache (capacity)
  , mkCache
  , getMap
  , putItem
  , findItem
  , removeItem
  , removeItems
  ) where

import Data.Maybe (isJust)
import Data.IORef
import Control.Exception (bracket_)
import Control.Monad (when)
-- import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (ExceptT(ExceptT))
import qualified Data.Map.Strict as Map
import Control.Concurrent (MVar, newMVar, takeMVar, putMVar)

import Bolour.Util.MiscUtil (IOEither, IOExceptT)

-- TODO. Implement LRU as an option.
-- For expedience temporarily clients have to set a high enough capacity.

-- | Cache of items - managed explicitly by clients.
--   If full errors out on additions. For now cache functions use Strings
--   as errors in Left. TODO. Provide data errors for cache.
data Cache key value = Cache { -- private constructor
    capacity :: Int     -- ^ public
  , lock :: MVar ()     -- ^ private
  , itemMapRef :: IORef (Map.Map key value) -- ^ private
}

itemMap :: Map.Map key value
itemMap = Map.empty

-- | Factory function (constructor is private).
mkCache :: (Ord key) => Int -> IO (Cache key value)
mkCache capacity = do
  ref <- newIORef itemMap
  lock <- newMVar ()
  return $ Cache capacity lock ref

-- | Put an item into the cache. If the key exists, the value is replaced.
--   If the key does not exist and the cache if full an error is returned in Left.
putItem :: (Ord key, Show key) => Cache key value -> key -> value -> IOExceptT String ()
putItem (cache @ (Cache {lock})) key value =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (putItemInternal cache key value)
  in ExceptT ioEither

putItemInternal :: (Ord key, Show key) => Cache key value -> key -> value -> IOEither String ()
putItemInternal (Cache {capacity, itemMapRef}) key value = do
  map <- readIORef itemMapRef
  let num = Map.size map
  if num < capacity
    then do
      res <- modifyIORef itemMapRef (Map.insert key value)
      return $ Right res
    else return $ Left $ "cache is full at capacity: " ++ show capacity

-- | Lookup a function in the cache.
findItem :: (Ord key, Show key) => Cache key value -> key -> IOExceptT String value
findItem (cache @ (Cache {lock})) key =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (findItemInternal cache key)
  in ExceptT ioEither

findItemInternal :: (Ord key, Show key) => Cache key value -> key -> IOEither String value
findItemInternal (Cache {itemMapRef}) key = do
  map <- readIORef itemMapRef
  let maybeValue = Map.lookup key map
  case maybeValue of
    Nothing -> return $ Left $ "no item for this key in cache: " ++ show key
    Just value -> return $ Right value

-- | Remove an item from teh cache. Returns an error if not found.
removeItem :: (Ord key, Show key) => Cache key value -> key -> IOExceptT String ()
removeItem (cache @ (Cache {lock})) key =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (removeItemInternal cache key)
  in ExceptT ioEither

removeItemInternal :: (Ord key, Show key) => Cache key value -> key -> IOEither String ()
removeItemInternal (Cache {itemMapRef}) key = do
  map <- readIORef itemMapRef
  let maybeValue = Map.lookup key map
  case maybeValue of
    Nothing -> return $ Left $ "no item for this key in cache: " ++ show key
    Just value -> do
      res <- modifyIORef itemMapRef (Map.delete key)
      return $ Right res

removeItemIfExistsInternal :: (Ord key) => Cache key value -> key -> IOEither String ()
removeItemIfExistsInternal (Cache {itemMapRef}) key = do
  map <- readIORef itemMapRef
  let maybeValue = Map.lookup key map
  when (isJust maybeValue) (modifyIORef itemMapRef (Map.delete key))
  return $ Right ()

-- | Remove a set of items from the cache.
removeItems :: (Ord key) => Cache key value -> [key] -> IOExceptT String ()
removeItems (cache @ Cache {lock}) keys =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (removeItemsInternal cache keys)
  in ExceptT ioEither

removeItemsInternal :: (Ord key) => Cache key value -> [key] -> IOEither String ()
removeItemsInternal cache keys =
  let dummy = removeItemIfExistsInternal cache <$> keys
  in return $ Right ()

-- | Get the key-value map of the items in the cache.
getMap :: (Ord key) => Cache key value -> IOExceptT String (Map.Map key value)
getMap Cache {itemMapRef, lock} =
  let ioMap = bracket_ (takeMVar lock) (putMVar lock ()) $ readIORef itemMapRef
      mapRight io = Right <$> io
  in ExceptT (mapRight ioMap)

