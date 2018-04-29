--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

-- TODO. Use the generic Bolour.Util.Cache to implement the game cache.

module BoardGame.Server.Domain.GameCache (
    mkGameCache
  , cacheGetGamesMap
  , insert
  , lookup
  , delete
  , deleteItems
  , GameCache(..)
  ) where

import Prelude hiding (lookup)
import Data.IORef
import qualified Data.Map.Strict as Map

import Control.Exception (bracket_)
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Control.Concurrent (MVar, newMVar, takeMVar, putMVar)

import BoardGame.Server.Domain.Game(Game)
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.GameError
import Bolour.Util.MiscUtil (IOEither, IOExceptT)

-- | Cache of active games.
data GameCache = GameCache {
    capacity :: Int
  , lock :: MVar ()
  , gameMapRef :: IORef (Map.Map String Game)
}

gameMap :: Map.Map String Game
gameMap = Map.empty

mkGameCache :: Int -> IO GameCache
mkGameCache capacity = do
  ref <- newIORef gameMap
  lock <- newMVar ()
  return $ GameCache capacity lock ref

-- type GameIOEither a = IO (Either GameError a)

-- TODO. Just use generic Cache for game cache. Most of this code is duplicated in Cache.
-- But generic cache uses String for errors not GameError used here.
-- Generic cache should use a generic error class.
-- That class will need to get translated to GameError in clients of Cache.do
-- This module can then be removed.

-- TODO. Don't know how to use bracket with constraints MonadIO m, MonadError GameError m to return an m.

insert :: Game -> GameCache -> IOExceptT GameError ()
insert game (cache @ (GameCache {lock})) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (insertInternal game cache)
  in ExceptT ioEither

insertInternal :: Game -> GameCache -> IOEither GameError ()
insertInternal game (GameCache {gameMapRef}) = do
  let gameId = Game.gameId game
  map <- readIORef gameMapRef
  let numGames = Map.size map
  if numGames < 100 -- TODO. Use configured number.
    then do
      res <- modifyIORef gameMapRef (Map.insert gameId game)
      return $ Right res
    else return $ Left SystemOverloadedError

-- TODO. If game is not in cache check the database.
-- Differentiate timed-out games from non-existent games.
-- For now assume that the game existed and was timed out and ejected from the cache.

lookup :: String -> GameCache -> IOExceptT GameError Game
lookup game (cache @ (GameCache {lock})) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (lookupInternal game cache)
  in ExceptT ioEither

lookupInternal :: String -> GameCache -> IOEither GameError Game
lookupInternal gameId (GameCache {gameMapRef}) = do
  map <- readIORef gameMapRef
  let maybeGame = Map.lookup gameId map
  case maybeGame of
    Nothing -> return $ Left $ GameTimeoutError gameId
    Just game -> return $ Right game

delete :: String -> GameCache -> IOExceptT GameError ()
delete gameId (cache @ (GameCache {lock})) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (deleteInternal gameId cache)
  in ExceptT ioEither

deleteInternal :: String -> GameCache -> IOEither GameError ()
deleteInternal gameId (GameCache {gameMapRef}) = do
  map <- readIORef gameMapRef
  let maybeGame = Map.lookup gameId map
  case maybeGame of
    Nothing -> return $ Left $ GameTimeoutError gameId
    Just game -> do
      res <- modifyIORef gameMapRef (Map.delete gameId)
      return $ Right res

deleteInternalIfExists :: String -> GameCache -> IO ()
deleteInternalIfExists gameId (GameCache {gameMapRef}) = do
  map <- readIORef gameMapRef
  let maybeGame = Map.lookup gameId map
  case maybeGame of
    Nothing -> return ()
    Just game -> modifyIORef gameMapRef (Map.delete gameId)

deleteItems :: [String] -> GameCache -> IOExceptT GameError ()
deleteItems gameIds (cache @ GameCache {lock}) =
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (deleteItemsInternal gameIds cache)
  in ExceptT ioEither

deleteItemsInternal :: [String] -> GameCache -> IOEither GameError ()
deleteItemsInternal gameIds cache =
  let dummy = flip deleteInternalIfExists cache <$> gameIds
  in return $ Right ()

cacheGetGamesMap :: (MonadIO m) => GameCache -> m (Map.Map String Game)
cacheGetGamesMap GameCache {gameMapRef, lock} =
  liftIO $ bracket_ (takeMVar lock) (putMVar lock ()) $ readIORef gameMapRef

