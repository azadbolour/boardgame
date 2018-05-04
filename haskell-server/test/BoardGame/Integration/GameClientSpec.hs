--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Integration.GameClientSpec (
    spec
  ) where

import Data.Char (isUpper, toUpper)
import Data.Maybe (fromJust)
import Data.List
import Control.Concurrent (ThreadId, killThread)
import Control.Monad.Except (runExceptT)
import Test.Hspec
import Network.HTTP.Client (Manager, newManager, defaultManagerSettings)
import Servant.Client
import Servant.Common.BaseUrl()

import BoardGame.Common.Domain.Piece (Piece(Piece))
import BoardGame.Common.Domain.InitPieces (InitPieces(InitPieces))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.PlayPiece (PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece

import Bolour.Plane.Domain.Point (Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
-- import qualified Bolour.Plane.Domain.Point as Point
import BoardGame.Common.Domain.GameParams (GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Common.Domain.PlayerDto (PlayerDto(PlayerDto))
import BoardGame.Common.Message.SwapPieceResponse (SwapPieceResponse(..))
import qualified BoardGame.Common.Message.StartGameResponse as StartGameResponse
import BoardGame.Common.Message.StartGameRequest (StartGameRequest(StartGameRequest))
import BoardGame.Common.Message.CommitPlayResponse (CommitPlayResponse, CommitPlayResponse(CommitPlayResponse))
import qualified BoardGame.Common.Message.CommitPlayResponse as CommitPlayResponse
import BoardGame.Common.Message.MachinePlayResponse (MachinePlayResponse, MachinePlayResponse(MachinePlayResponse))
import qualified BoardGame.Common.Message.MachinePlayResponse as MachinePlayResponse

import qualified BoardGame.Server.Web.GameEndPoint as GameEndPoint
import qualified BoardGame.Util.TestUtil as TestUtil
import qualified Bolour.Util.SpecUtil as SpecUtil
import BoardGame.Server.Domain.GameEnv (GameEnv, GameEnv(GameEnv))
import qualified BoardGame.Server.Domain.GameEnv as GameEnv

import qualified Bolour.Util.PersistRunner as PersistRunner
import Bolour.Util.PersistRunner (ConnectionProvider)
import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig), DeployEnv(..))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig

import BoardGame.Server.Domain.GameEnv (GameEnv(GameEnv))
import Bolour.Util.WaiUtil
import qualified BoardGame.Client.GameClient as Client
import qualified Bolour.Language.Domain.WordDictionary as Dict
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified Bolour.Language.Domain.DictionaryCache as DictCache
import qualified Bolour.Language.Domain.DictionaryIO as DictIO
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType

import BoardGame.Server.Service.GamePersister (GamePersister, GamePersister(GamePersister))
import qualified BoardGame.Server.Service.GamePersister as GamePersister
import qualified BoardGame.Server.Service.GamePersisterJsonBridge as GamePersisterJsonBridge
import qualified BoardGame.Server.Service.GameJsonSqlPersister as GameJsonSqlPersister
import qualified BoardGame.Server.Service.GameJsonSqlPersister as GamePersister
import qualified BoardGame.Server.Domain.ServerVersion as ServerVersion

-- TODO. Start the server within the test - just copy main and test against it.
-- TODO. Need to shut down the server.

-- First we test against an external server.
-- In this first version the server has to be running for the test to succeed.

-- TODO. How to access the values returned by beforeAll within the test.

mkPersister :: ConnectionProvider -> GamePersister
mkPersister connectionProvider =
  let jsonPersister = GameJsonSqlPersister.mkPersister connectionProvider
      version = ServerVersion.version
  in GamePersisterJsonBridge.mkBridge jsonPersister version

testConfigPath = "test-data/test-config.yml"

getGameEnv :: IO GameEnv
getGameEnv = do
  serverConfig <- ServerConfig.getServerConfig $ Just testConfigPath
  let ServerConfig {maxActiveGames, dbConfig} = serverConfig
  connectionProvider <- PersistRunner.mkConnectionProvider dbConfig
  let persister @ GamePersister {migrate} = mkPersister connectionProvider
  runExceptT migrate
  runExceptT $ GamePersister.clearAllData persister
  cache <- GameCache.mkGameCache maxActiveGames
  dictionaryDir <- GameEnv.getDictionaryDir "data"
  -- dictionaryCache <- DictCache.mkCache dictionaryDir 100 2
  Right dictionaryCache <- runExceptT $ DictIO.readAllDictionaries dictionaryDir ["tiny"] 100 2
  return $ GameEnv serverConfig connectionProvider cache dictionaryCache

startApp :: IO (ThreadId, BaseUrl)
startApp = do
  gameEnv <- getGameEnv
  let gameApp = GameEndPoint.mkGameApp gameEnv
  startWaiApp gameApp

-- TODO. Duplicated in WebTestFixtures. Unify into single fixture module.

dimension = 9
center = dimension `div` 2
thePlayer = "You"
pieceProviderType = PieceProviderType.Cyclic
params = GameParams dimension 12 "tiny" thePlayer pieceProviderType
-- params = GameParams dimension 12 Dict.defaultLanguageCode thePlayer pieceProviderType

pointValues :: [[Int]]
pointValues = replicate dimension $ replicate dimension 1

centerGridPoint = Point center center

-- TODO. End duplicated

spec :: Spec
spec = beforeAll startApp $ afterAll endWaiApp $
  describe "start a game and make a player play and a machine play" $
    it "start a game and make a player play and a machine play" $ \(_, baseUrl) -> do
      (threadId, baseUrl) <- startApp
      initTest
      manager <- mkManager
      eitherMaybeUnit <- runExceptT (Client.addPlayer (PlayerDto thePlayer) manager baseUrl)

      let uPieces = [Piece 'B' "1", Piece 'E' "2", Piece 'T' "3"] -- Allow the word 'BET'
          mPieces = [Piece 'S' "4", Piece 'T' "5", Piece 'Z' "6"] -- Allow the word 'SET' across.
          initPieces = InitPieces [] uPieces mPieces

      StartGameResponse.StartGameResponse {gameId, trayPieces} <- SpecUtil.satisfiesRight
        =<< runExceptT (Client.startGame (StartGameRequest params initPieces pointValues) manager baseUrl)

      let pc0:pc1:pc2:_ = uPieces
          center = dimension `div` 2
          playPieces = [
              PlayPiece pc0 (Point center (center - 1)) True
            , PlayPiece pc1 (Point center center) True
            , PlayPiece pc2 (Point center (center + 1)) True
            ]

      -- replacements <- SpecUtil.satisfiesRight =<< runExceptT (Client.commitPlay gameId playPieces manager baseUrl)
      CommitPlayResponse {gameMiniState, replacementPieces} <- SpecUtil.satisfiesRight =<< runExceptT (Client.commitPlay gameId playPieces manager baseUrl)
      length replacementPieces `shouldBe` 3
      -- wordPlayPieces <- SpecUtil.satisfiesRight
      MachinePlayResponse {gameMiniState, playedPieces} <- SpecUtil.satisfiesRight
        =<< runExceptT (Client.machinePlay gameId manager baseUrl)
      print $ PlayPiece.playPiecesToWord playedPieces
      let piece = last trayPieces
      SwapPieceResponse {gameMiniState, piece = swappedPiece} <- SpecUtil.satisfiesRight
         =<< runExceptT (Client.swapPiece gameId piece manager baseUrl)
      let Piece {value} = swappedPiece
      value `shouldSatisfy` isUpper
      killThread threadId

initTest :: IO ()
initTest = do
  gameEnv @ GameEnv {connectionProvider} <- getGameEnv
  return ()

mkManager :: IO Manager
mkManager = newManager defaultManagerSettings

