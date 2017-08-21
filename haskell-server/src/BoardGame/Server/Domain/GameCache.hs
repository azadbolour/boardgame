--
-- Copyright 2017 Azad Bolour
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
  , cachePutGame
  , cacheFindGame
  , cacheRemoveGame
  , cacheRemoveGames
  , GameCache(..)
  ) where

import Data.IORef
import qualified Data.Map.Strict as Map

import Control.Exception (bracket_)
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..))
import Control.Concurrent (MVar, newMVar, takeMVar, putMVar)

import BoardGame.Server.Domain.Game(Game)
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.GameError

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

-- TODO. Move to GameError.
type GameIOEither a = IO (Either GameError a)


{-
   Note. The 'lifter function' parameter in cache functions.
   TODO. Should do the lifting to the transformer stack in the callers.
   This would leave the cache api simple based only on IO and Either.
   But for the moment, the lifting is done in the cache api

   To manipulate the cache, it is sufficient to just run in the IO monad.
   Therefore, we use 'bracket_', which runs in the IO monad to lock and unlock the cache
   before and after operations on the cache.

   However, cache functions are invoked in the game transformer monad.
   So the results of cache operations need to be lifter to the game transformer monad.

   The lifter has to be passed in since it is dependent on teh game transformer
   stack, and implementing it here in the cache module would cause a circular
   dependency between the cache and the game transformer stack (which happens to
   be dependent on teh cache).

-}

cachePutGame :: (MonadIO m, MonadError GameError m) => GameCache -> Game -> (GameIOEither () -> m ()) -> m ()
cachePutGame (cache @ (GameCache {lock})) game lifter = do
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (putGameInternal cache game)
  lifter ioEither

putGameInternal :: GameCache -> Game -> GameIOEither ()
putGameInternal (GameCache {gameMapRef}) (game @ Game.Game {gameId}) = do
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

cacheFindGame :: (MonadError GameError m, MonadIO m) => GameCache -> String -> (GameIOEither Game -> m Game) -> m Game
cacheFindGame (cache @ (GameCache {lock})) game lifter = do
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (findGameInternal cache game)
  lifter ioEither

findGameInternal :: GameCache -> String -> IO (Either GameError Game) -- TODO. GameIOEither Game.
findGameInternal (GameCache {gameMapRef}) gameId = do
  map <- readIORef gameMapRef
  let maybeGame = Map.lookup gameId map
  case maybeGame of
    Nothing -> return $ Left $ GameTimeoutError gameId
    Just game -> return $ Right game

cacheRemoveGame :: (MonadError GameError m, MonadIO m) => GameCache -> String -> (GameIOEither () -> m ()) -> m ()
cacheRemoveGame (cache @ (GameCache {lock})) gameId lifter = do
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (removeGameInternal cache gameId)
  lifter ioEither

removeGameInternal :: GameCache -> String -> IO (Either GameError ()) -- TODO. GameIOEither ().
removeGameInternal (GameCache {gameMapRef}) gameId = do
  map <- readIORef gameMapRef
  let maybeGame = Map.lookup gameId map
  case maybeGame of
    Nothing -> return $ Left $ GameTimeoutError gameId
    Just game -> do
      res <- modifyIORef gameMapRef (Map.delete gameId)
      return $ Right res

removeGameIfExistsInternal :: GameCache -> String -> IO ()
removeGameIfExistsInternal (GameCache {gameMapRef}) gameId = do
  map <- readIORef gameMapRef
  let maybeGame = Map.lookup gameId map
  case maybeGame of
    Nothing -> return ()
    Just game -> modifyIORef gameMapRef (Map.delete gameId)

cacheRemoveGames :: (MonadError GameError m, MonadIO m) => GameCache -> [String] -> (GameIOEither () -> m ()) -> m ()
cacheRemoveGames (cache @ GameCache {lock}) gameIds lifter = do
  let ioEither = bracket_ (takeMVar lock) (putMVar lock ()) (removeGamesInternal cache gameIds)
  lifter ioEither

removeGamesInternal :: GameCache -> [String] -> GameIOEither ()
removeGamesInternal cache gameIds =
  let dummy = removeGameIfExistsInternal cache <$> gameIds
  in return $ Right ()

cacheGetGamesMap :: (MonadIO m) => GameCache -> m (Map.Map String Game)
cacheGetGamesMap GameCache {gameMapRef, lock} =
  liftIO $ bracket_ (takeMVar lock) (putMVar lock ()) $ readIORef gameMapRef

