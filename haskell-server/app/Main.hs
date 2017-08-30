--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Main where

import System.Environment (getArgs)
import Data.Char (toUpper)
import Data.String.Here.Interpolated (iTrim)
import Control.Monad (forever)
import Control.Concurrent (forkIO, threadDelay)
import Control.Monad.Except (ExceptT(ExceptT))
import Network.Wai (Middleware)
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Cors

import qualified Bolour.Util.HttpUtil as HttpUtil
import Bolour.Util.Middleware (optionsHandler, mkMiddlewareLogger, gameCorsMiddleware)
import Bolour.Util.DbUtil (makePool)

import qualified BoardGame.Server.Domain.GameConfig as Config
import BoardGame.Server.Domain.GameEnv (GameEnv(..))
import qualified Bolour.Util.StaticTextFileCache as FileCache
import qualified BoardGame.Server.Domain.DictionaryCache as DictCache
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters
import BoardGame.Server.Web.GameEndPoint (mkGameApp)
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified BoardGame.Server.Service.GameTransformerStack as TransformerStack
import qualified BoardGame.Server.Service.GameService as GameService

-- TODO. Use server parameter.

harvestInterval :: Int
harvestInterval = 1000000 * 60 * 5 -- micros - reduce for testing
-- harvestInterval = 1000000 * 2 -- micros - increase for production

-- Note. The term environment has two different meanings. It can
-- designate the deployment context of the application,
-- as in DEV, TEST, PROD. Or it can designate the context in which
-- the reader monad (or more generally our monad transformer stack, which
-- includes a reader monad) is being run. To disambiguate we use the
-- term 'deployment environment' for the 'name' of the environment
-- in which the entire application is being run, and the term
-- 'game environment' for the context of the reader monad and its
-- derived monad transformers. The latter is represented in the GameEnv type.

-- TODO. Use getOpt. from System.Console.GetOpt.

maxDictionaries = 100

main :: IO ()
main = do
    args <- getArgs
    let maybeConfigPath = if null args then Nothing else Just $ head args
    serverParameters <- Config.getServerParameters maybeConfigPath
    let ServerParameters.ServerParameters {deployEnv, serverPort, maxActiveGames, dictionaryDir} = serverParameters
    myPool <- makePool serverParameters
    print [iTrim|running Warp server on port '${serverPort}' for env '${deployEnv}'|]
    config <- Config.mkConfig serverParameters myPool
    cache <- GameCache.mkGameCache maxActiveGames
    let logger = mkMiddlewareLogger deployEnv
    -- dictionaryCache <- FileCache.mkCache maxDictionaries (toUpper <$>)
    dictionaryCache <- DictCache.mkCache dictionaryDir maxDictionaries
    let gameEnv = GameEnv config cache dictionaryCache
    gameApp <- mkGameApp gameEnv
    forkIO $ longRunningGamesHarvester gameEnv
    run serverPort $ logger $ myOptionsHandler $ simpleCors gameApp
    -- run serverPort $ logger $ gameCorsMiddleware $ simpleCors gameApp -- could nt get this to work

-- TODO. simpleCors is a security risk.
-- It was the simplest way to get going in development.

myOptionsHandler :: Middleware
myOptionsHandler = optionsHandler HttpUtil.defaultOptionsHeaders

longRunningGamesHarvester :: GameEnv -> IO ()
longRunningGamesHarvester env =
  forever $ do
    threadDelay harvestInterval
    let ExceptT ioEither = TransformerStack.runDefault env GameService.timeoutLongRunningGames
    leftOrRight <- ioEither
    print "havest of aged games completed" -- TODO. Remove once tested - don't clutter the log.


