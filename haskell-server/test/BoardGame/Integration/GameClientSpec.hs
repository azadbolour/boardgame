--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

-- See https://docs.servant.dev/en/stable/cookbook/testing/Testing.html.

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
import Servant
import Servant.Client
import Servant.Server
import Network.Wai (Application)

import BoardGame.Common.GameApi (GameApi, gameApi)
import BoardGame.Common.Domain.Piece (Piece(Piece))
import BoardGame.Common.Domain.InitPieces (InitPieces(InitPieces))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.PlayPiece (PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece

import Bolour.Plane.Domain.Point (Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
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
import BoardGame.Server.Web.GameEndPoint(mkGameApp)

import qualified Network.Wai.Handler.Warp as Warp

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

getGameApp :: IO Application
getGameApp = do
  env <- getGameEnv
  mkGameApp env

withGameApp :: (Warp.Port -> IO ()) -> IO ()
withGameApp action =
  -- testWithApplication makes sure the action is executed after the server has
  -- started and is being properly shutdown.
  Warp.testWithApplication getGameApp action
  -- Warp.testWithApplication (pure userApp) action

-- TODO. Duplicated in WebTestFixtures. Unify into single fixture module.

dimension = 9
center = dimension `div` 2
thePlayer = "You"
pieceProviderType = PieceProviderType.Cyclic
params = GameParams dimension 12 "tiny" thePlayer pieceProviderType

pointValues :: [[Int]]
pointValues = replicate dimension $ replicate dimension 1

centerGridPoint = Point center center

-- TODO. End duplicated

spec :: Spec
spec = around withGameApp $ do
  -- let gameClient = client (Proxy :: Proxy GameApi)
  baseUrl <- runIO $ parseBaseUrl "http://localhost"
  manager <- runIO $ newManager defaultManagerSettings
  let clientEnv port = mkClientEnv manager (baseUrl { baseUrlPort = port })

  describe "start a game and make a player play and a machine play" $
    it "start a game and make a player play and a machine play" $ \port -> do

      -- eitherMaybeUnit <- runExceptT (Client.addPlayer (PlayerDto thePlayer) manager baseUrl)
      eitherMaybeUnit <- runClientM (Client.addPlayer (PlayerDto thePlayer)) (clientEnv port)

      let uPieces = [Piece 'B' "1", Piece 'E' "2", Piece 'T' "3"] -- Allow the word 'BET'
          mPieces = [Piece 'S' "4", Piece 'T' "5", Piece 'Z' "6"] -- Allow the word 'SET' across.
          initPieces = InitPieces [] uPieces mPieces

      StartGameResponse.StartGameResponse {gameId, trayPieces} <- SpecUtil.satisfiesRight
        =<< runClientM (Client.startGame (StartGameRequest params initPieces pointValues)) (clientEnv port)

      let pc0:pc1:pc2:_ = uPieces
          center = dimension `div` 2
          playPieces = [
              PlayPiece pc0 (Point center (center - 1)) True
            , PlayPiece pc1 (Point center center) True
            , PlayPiece pc2 (Point center (center + 1)) True
            ]

      CommitPlayResponse {gameMiniState, replacementPieces} <- SpecUtil.satisfiesRight
        =<< runClientM (Client.commitPlay gameId playPieces) (clientEnv port)
      length replacementPieces `shouldBe` 3
      MachinePlayResponse {gameMiniState, playedPieces} <- SpecUtil.satisfiesRight
        =<< runClientM (Client.machinePlay gameId) (clientEnv port)
      print $ PlayPiece.playPiecesToWord playedPieces
      let piece = last trayPieces
      SwapPieceResponse {gameMiniState, piece = swappedPiece} <- SpecUtil.satisfiesRight
         =<< runClientM (Client.swapPiece gameId piece) (clientEnv port)
      let Piece {value} = swappedPiece
      value `shouldSatisfy` isUpper
      return ()


