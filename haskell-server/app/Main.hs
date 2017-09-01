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
import Data.String.Here.Interpolated (iTrim)
import Control.Monad (forever)
import Control.Concurrent (forkIO, threadDelay)
import Control.Monad.Except (ExceptT(ExceptT))
import Network.Wai (Middleware)
import qualified Network.Wai.Handler.Warp as Warp (run)
import Network.Wai.Middleware.Cors

import qualified Bolour.Util.DbUtil as DbUtil (makePool)
import qualified Bolour.Util.HttpUtil as HttpUtil
import qualified Bolour.Util.Middleware as MyMiddleware

import qualified BoardGame.Server.Domain.GameConfig as Config
import BoardGame.Server.Domain.GameEnv (GameEnv(..))
import qualified BoardGame.Server.Domain.DictionaryCache as DictCache
import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary)
import BoardGame.Server.Domain.IndexedLanguageDictionary (IndexedLanguageDictionary)
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters
import BoardGame.Server.Domain.GameConfig (ServerParameters, ServerParameters(ServerParameters))
import qualified BoardGame.Server.Web.GameEndPoint as GameEndPoint (mkGameApp)
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified BoardGame.Server.Service.GameTransformerStack as TransformerStack
import qualified BoardGame.Server.Service.GameService as GameService

-- | Timer interval for harvesting long-running games (considered abandoned).
harvestInterval :: Int
harvestInterval = 1000000 * 60 * 5 -- micros - reduce for testing
-- harvestInterval = 1000000 * 2 -- micros - increase for production

-- Terminology. The term 'environment' may mean a deployment environment
-- (DEV, TEST, PROD), or a reader monad environment. We use the
-- terms 'deployment environment' for the former and 'game environment'
-- (GameEnv) for the latter.

-- | Maximum number of language dictionaries (different language codes that can be used).
maxDictionaries = 100

main :: IO ()
main = do
    serverParameters <- getParameters
    let ServerParameters {deployEnv, serverPort} = serverParameters
    gameEnv <- mkGameEnv serverParameters
    gameApp <- GameEndPoint.mkGameApp gameEnv
    forkIO $ longRunningGamesHarvester gameEnv
    print [iTrim|running Warp server on port '${serverPort}' for env '${deployEnv}'|]
    let logger = MyMiddleware.mkMiddlewareLogger deployEnv
    Warp.run serverPort $ logger $ myOptionsHandler $ simpleCors gameApp

-- Could not get this to work:
-- Warp.run serverPort $ logger $ MyMiddleware.gameCorsMiddleware $ simpleCors gameApp
-- TODO. simpleCors is a security risk. Fix.

getParameters :: IO ServerParameters
getParameters = do
    -- TODO. Use getOpt. from System.Console.GetOpt.
    args <- getArgs
    let maybeConfigPath = if null args then Nothing else Just $ head args
    Config.getServerParameters maybeConfigPath

mkGameEnv ::
  ServerParameters -> IO (GameEnv IndexedLanguageDictionary)
mkGameEnv serverParameters = do
    let ServerParameters {maxActiveGames, dictionaryDir} = serverParameters
    myPool <- DbUtil.makePool serverParameters
    config <- Config.mkConfig serverParameters myPool
    gameCache <- GameCache.mkGameCache maxActiveGames
    dictionaryCache <- DictCache.mkCache dictionaryDir maxDictionaries
    return $ GameEnv config gameCache dictionaryCache

-- | Interceptor for HTTP OPTIONS methods.
myOptionsHandler :: Middleware
myOptionsHandler = MyMiddleware.optionsHandler HttpUtil.defaultOptionsHeaders

longRunningGamesHarvester :: LanguageDictionary dictionary =>
  GameEnv dictionary -> IO ()
longRunningGamesHarvester env =
  forever $ do
    threadDelay harvestInterval
    let ExceptT ioEither = TransformerStack.runDefault env GameService.timeoutLongRunningGames
    leftOrRight <- ioEither
    -- print "harvest of aged games completed"
    return ()


