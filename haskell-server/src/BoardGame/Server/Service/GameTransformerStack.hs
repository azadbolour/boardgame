--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Service.GameTransformerStack (
    GameTransformerStack
  , liftGameExceptToStack
  , run
  , runDefault
  , runUnprotected
  , runDefaultUnprotected
  , logger
) where

import Control.Monad.Trans.Class (lift)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Except (ExceptT, ExceptT(ExceptT))
import Control.Monad.Reader (ReaderT, runReaderT)
import Control.Monad.Log (LoggingT, runLoggingT)
import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAnyDeep)
import Control.DeepSeq (NFData)

import BoardGame.Server.Domain.GameEnv (GameEnv)
import BoardGame.Server.Domain.GameError (GameError, ExceptGame, GameError(InternalError))

-- TODO. It would be instructive to figure out how each type class instance is derived.
-- TODO. Is a new type necessary - or could we just use the stack itself?

-- | The monad transformer stack used in the higher layers of the game application.
--   Composes the effects of reader, logger, error, with IO.
type GameTransformerStack result = ReaderT GameEnv (LoggingT String (ExceptT GameError IO)) result

-- | Sample logging function used with the logging monad.
logger :: String -> ExceptGame ()
logger s = do
  liftIO $ print s
  return ()

-- | Build a game transformer stack from a low-level stack: result of
--   low-level function calls packaged in ExceptGame representing both
--   either and IO effects.
liftGameExceptToStack :: ExceptGame result -> GameTransformerStack result
liftGameExceptToStack exceptGame = lift $ lift exceptGame

-- TODO. Low-level functions doing IO should return ExceptGame rather than just IO.
-- Then use the above lift function to transform them to the stack.

-- | Execute a game transformer stack, providing its logger with
--   a logging function, and its reader with an environment.
run :: (NFData result) =>
     (String -> ExceptGame ())        -- ^ The logging function to be used by the stack's logging monad.
  -> GameEnv                          -- ^ The environment to be used by the stack's reader monad.
  -> GameTransformerStack result      -- ^ The stack to execute.
  -> ExceptGame result                -- ^ The result of execution upon resolution of the logger and reader.

run logger env stack =
  flip runLoggingT logger $ runReaderT (catcher stack) env

-- | Execute a game transformer stack with default logging.
runDefault :: (NFData result) => GameEnv -> GameTransformerStack result -> ExceptGame result
runDefault = run logger

runUnprotected ::
     (String -> ExceptGame ())        -- ^ The logging function to be used by the stack's logging monad.
  -> GameEnv                          -- ^ The environment to be used by the stack's reader monad.
  -> GameTransformerStack result      -- ^ The stack to execute.
  -> ExceptGame result                -- ^ The result of execution upon resolution of the logger and reader.

runUnprotected logger env stack =
  flip runLoggingT logger $ runReaderT stack env

runDefaultUnprotected :: GameEnv -> GameTransformerStack result -> ExceptGame result
runDefaultUnprotected = runUnprotected logger

-- Note: catchAnyDeep forces the evaluation of the result (a)
-- making sure all exceptions surface.
-- But it means polluting the code with 'deriving (NFData)'
-- for any actual parameters of the transformer stack.
catcher :: (NFData a) => GameTransformerStack a -> GameTransformerStack a
catcher stack =
  catchAnyDeep stack (liftGameExceptToStack . exceptionToGameExcept)

exceptionToGameExcept :: SomeException -> ExceptGame a
exceptionToGameExcept someEx = ExceptT $ return $ Left $ InternalError $ show someEx





