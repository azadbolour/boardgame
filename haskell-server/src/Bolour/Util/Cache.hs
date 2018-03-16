--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module Bolour.Util.Cache (
    Cache (capacity)
  , mkCache
  , getMap
  , insert
  , lookup
  , delete
  , deleteItems
  ) where

import Prelude hiding (lookup)
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
insert :: (Ord key, Show key) => key -> value -> Cache key value -> IOExceptT String ()
insert key value  (cache @ (Cache {lock})) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (insertInternal key value cache)
  in ExceptT ioEither

insertInternal :: (Ord key, Show key) => key -> value -> Cache key value -> IOEither String ()
insertInternal key value (Cache {capacity, itemMapRef}) = do
  map <- readIORef itemMapRef
  let num = Map.size map
  if num < capacity
    then do
      res <- modifyIORef itemMapRef (Map.insert key value)
      return $ Right res
    else return $ Left $ "cache is full at capacity: " ++ show capacity

-- | Lookup a function in the cache.
lookup :: (Ord key, Show key) => key -> Cache key value -> IOExceptT String value
lookup key (cache @ (Cache {lock})) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (lookupInternal key cache)
  in ExceptT ioEither

lookupInternal :: (Ord key, Show key) => key -> Cache key value -> IOEither String value
lookupInternal key (Cache {itemMapRef}) = do
  map <- readIORef itemMapRef
  let maybeValue = Map.lookup key map
  case maybeValue of
    Nothing -> return $ Left $ "no item for this key in cache: " ++ show key
    Just value -> return $ Right value

-- | Remove an item from teh cache. Returns an error if not found.
delete :: (Ord key, Show key) => key -> Cache key value -> IOExceptT String ()
delete key (cache @ (Cache {lock})) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (deleteInternal key cache)
  in ExceptT ioEither

deleteInternal :: (Ord key, Show key) => key -> Cache key value -> IOEither String ()
deleteInternal key (Cache {itemMapRef}) = do
  map <- readIORef itemMapRef
  let maybeValue = Map.lookup key map
  case maybeValue of
    Nothing -> return $ Left $ "no item for this key in cache: " ++ show key
    Just value -> do
      res <- modifyIORef itemMapRef (Map.delete key)
      return $ Right res

deleteInternalIfExists :: (Ord key) => Cache key value -> key -> IOEither String ()
deleteInternalIfExists (Cache {itemMapRef}) key = do
  map <- readIORef itemMapRef
  let maybeValue = Map.lookup key map
  when (isJust maybeValue) (modifyIORef itemMapRef (Map.delete key))
  return $ Right ()

-- | Remove a set of items from the cache.
deleteItems :: (Ord key) => [key] -> Cache key value -> IOExceptT String ()
deleteItems keys (cache @ Cache {lock}) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (deleteItemsInternal keys cache)
  in ExceptT ioEither

deleteItemsInternal :: (Ord key) => [key] -> Cache key value -> IOEither String ()
deleteItemsInternal keys cache =
  let dummy = deleteInternalIfExists cache <$> keys
  in return $ Right ()

-- | Get the key-value map of the items in the cache.
getMap :: (Ord key) => Cache key value -> IOExceptT String (Map.Map key value)
getMap Cache {itemMapRef, lock} =
  let ioMap = bracket_ (takeMVar lock) (putMVar lock ()) $ readIORef itemMapRef
      mapRight io = Right <$> io
  in ExceptT (mapRight ioMap)

