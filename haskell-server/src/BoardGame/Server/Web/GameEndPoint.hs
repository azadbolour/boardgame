--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE RankNTypes #-}

{-|

Implementation of the rest endpoints for the game application.

The implementation exposes a Warp application to be used
by the main program and by integration tests. Warp is the underlying
web server.

The application depends on a Servant server, defined as a list
of handlers for corresponding API functions.

The list elements are combined by a special list combinator :\<|\>
in the same order as their corresponding functions defined in
the API interface.

The game application depends on certain configuration parameters.
Hence this module exposes an application factory, a function called
mkGameApp, that takes the game configuration as a parameter and
returns the Warp application.

See http://haskell-servant.readthedocs.io/en/stable/tutorial/Server.html

-}
module BoardGame.Server.Web.GameEndPoint (
      mkGameApp
    , addPlayerHandler
    , startGameHandler
    , commitPlayHandler
    , machinePlayHandler
    , swapPieceHandler
    , endGameHandler
    , ExceptServant
) where

import Data.ByteString.Lazy.Char8 as BS
import Data.Aeson (encode)

import qualified Control.Exception as Exc
import Control.Monad.Except (ExceptT(..), withExceptT)
import Control.DeepSeq (NFData)

import Network.Wai (Application)
import Servant ((:<|>)(..))

import qualified Servant.Server as Servant
import qualified Servant.Utils.StaticFiles as ServantStatic

import Bolour.Util.MiscUtil (debug)

import BoardGame.Common.GameApi (GameApi, GameApi', gameApi')
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.Player (Player)
import BoardGame.Common.Domain.GameParams (GameParams(..))
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import BoardGame.Common.Message.GameDto (GameDto)
import BoardGame.Server.Domain.GameError (GameError(..), ExceptGame)
import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary)
import BoardGame.Server.Domain.GameEnv (GameEnv(..))
import BoardGame.Server.Service.GameTransformerStack (GameTransformerStack)
import qualified BoardGame.Server.Service.GameTransformerStack as TransformerStack
import BoardGame.Server.Web.Converters (toDto)
import qualified BoardGame.Server.Service.GameService as GameService

-- TODO. Simplify the api implementation by using the Servant 'enter' function.

mkGameApp :: LanguageDictionary dictionary =>
     GameEnv dictionary
  -> IO Application
mkGameApp env = return $ Servant.serve gameApi' $ mkServer' env

-- | The application server factory for the game api - based on the game environment.
mkServer :: LanguageDictionary dictionary =>
     GameEnv dictionary
  -> Servant.Server GameApi
mkServer env =
       addPlayerHandler env
  :<|> startGameHandler env
  :<|> commitPlayHandler env
  :<|> machinePlayHandler env
  :<|> swapPieceHandler env
  :<|> endGameHandler env

-- Note - In later versions of Servant this has changed - use ServantStatic.serveDirectoryFileServer "static".
-- Note also that the static handler has to be the last one in the list.
mkServer' :: LanguageDictionary dictionary =>
     GameEnv dictionary -> Servant.Server GameApi'
mkServer' env = mkServer env
               :<|> ServantStatic.serveDirectory "static"

-- | Return type of api handlers required by Servant.
type ExceptServant result = ExceptT Servant.ServantErr IO result

-- | Convert a game application ExceptT to a Servant ExceptT as
--   required by the game Servant API.
exceptTAdapter :: ExceptGame result -> ExceptServant result
exceptTAdapter gameExceptT = withExceptT gameErrorToServantErr gameExceptT

-- | Convert game application errors to Servant errors.
--   Lower-level modules return GameError in case of an error.
--   Servant require API handlers that return ServantErr.
--   This function converts a GameError returned by service calls
--   to a ServantErr required by Servant.
gameErrorToServantErr :: GameError -> Servant.ServantErr
-- Using 422 response code (unprocessable entity) for all errors. May want to distinguish later.
-- TODO. Use function GameError.gameErrorMessage so error messages can be specialized.
-- Default would be encode.
gameErrorToServantErr gameError = debug (show gameError) $ Servant.ServantErr
    422 -- errHTTPCode
    "Unprocessable entity." -- errReasonPhrase
    -- (BS.pack $ show gameError) -- errBody
    (encode gameError) -- errBody
    [] -- errHeaders

-- | Execute a game transformer stack, resolving its logger monad with
--   a fixed logging function, and resolving its reader monad
--   with a given environment, and returning a servant ExceptT as required
--   by Servant.
gameTransformerStackHandler :: (LanguageDictionary dictionary, NFData result) =>
  GameEnv dictionary -> GameTransformerStack dictionary result -> ExceptServant result
gameTransformerStackHandler env stack = exceptTAdapter $ TransformerStack.runDefault env stack

-- TODO. Pretty-printed logging for all requests and responses.
-- TODO. How to set logging level from the command line.

--
-- Servant handlers for api functions.
--

-- | API handler to register a new player.
addPlayerHandler :: LanguageDictionary dictionary =>
    GameEnv dictionary -> Player -> ExceptServant ()
addPlayerHandler env player =
  gameTransformerStackHandler env $ do -- GameTransformerStack
    result <- GameService.addPlayerService player
    -- logMessage (show result) -- TODO. Could not prettify it. Looks awful.
    return result

-- gameTransformerStackHandler env $ GameService.addPlayerService player

-- | API handler to create and start a new game.
startGameHandler :: LanguageDictionary dictionary =>
     GameEnv dictionary -> (GameParams, [GridPiece], [Piece], [Piece]) -> ExceptServant GameDto
startGameHandler env (params, gridPieces, initUserPieces, initMachinePieces) =
  gameTransformerStackHandler env $ do -- GameTransformerStack
    gameDto <- startGameServiceWrapper params gridPieces initUserPieces initMachinePieces
    -- logMessage (show gameDto) -- TODO. Could not prettify it - tried groom and pretty-show. No good.
    return gameDto

startGameServiceWrapper :: LanguageDictionary dictionary =>
     GameParams
  -> [GridPiece]
  -> [Piece]
  -> [Piece]
  -> GameTransformerStack dictionary GameDto
startGameServiceWrapper params gridPieces initUserPieces initMachinePieces = do
  game <- GameService.startGameService params gridPieces initUserPieces initMachinePieces
  return $ toDto game

-- | API handler to commit a new play by the player side of the game.
commitPlayHandler :: LanguageDictionary dictionary =>
  GameEnv dictionary -> String -> [PlayPiece] -> ExceptServant [Piece]
commitPlayHandler env gameId playPieces = gameTransformerStackHandler env $ GameService.commitPlayService gameId playPieces

-- | API handler to make a machine play.
machinePlayHandler :: LanguageDictionary dictionary =>
  GameEnv dictionary -> String -> ExceptServant [PlayPiece]
machinePlayHandler env gameId = gameTransformerStackHandler env $ GameService.machinePlayService gameId

-- | API handler to swap a piece.
swapPieceHandler :: LanguageDictionary dictionary =>
  GameEnv dictionary -> String -> Piece -> ExceptServant Piece
swapPieceHandler env gameId piece = gameTransformerStackHandler env $ GameService.swapPieceService gameId piece

endGameHandler :: LanguageDictionary dictionary =>
  GameEnv dictionary -> String -> ExceptServant ()
endGameHandler env gameId = gameTransformerStackHandler env $ GameService.endGameService gameId

-- | Convert an unknown exception that may be thrown by the Haskell
--   runtime or by lower-level libraries to a Servant error, as
--   needed by Servant API handlers.
exceptionToServantErr :: Exc.SomeException -> Servant.ServantErr
exceptionToServantErr exception = Servant.ServantErr
    500 -- errHTTPCode
    "Internal server error." -- errReasonPhrase
    (BS.pack $ show exception) -- errBody
    [] -- errHeaders

-- | Convert an unknown exception caught at the highest level
--  to the core of an ExceptT ServantErr IO monad, so it
--  can be embedded in an ExceptT ServantErr IO as required
--  by Servant. But how/where do you catch it. Catch is only for
--  the IO monad.
catchallHandler :: Exc.SomeException -> IO (Either Servant.ServantErr result)
catchallHandler exception = do
  print exception -- TODO. Should log rather than print.
  return (Left $ exceptionToServantErr exception)
