--
-- Copyright 2017 Azad Bolour
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
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.PlayPiece (PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import Bolour.Grid.GridValue (GridValue, GridValue(GridValue))
import qualified Bolour.Grid.GridValue as GridValue
import qualified BoardGame.Common.Domain.GridPiece as GridPiece

import Bolour.Grid.Point (Point(Point))
import qualified Bolour.Grid.Point as Point
-- import qualified Bolour.Grid.Point as Point
import BoardGame.Common.Domain.GameParams (GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Common.Domain.Player (Player(Player))
import BoardGame.Common.Message.SwapPieceResponse (SwapPieceResponse(..))
import qualified BoardGame.Common.Message.StartGameResponse as StartGameResponse
import BoardGame.Common.Message.StartGameRequest (StartGameRequest(StartGameRequest))
import BoardGame.Common.Message.CommitPlayResponse (CommitPlayResponse, CommitPlayResponse(CommitPlayResponse))
import qualified BoardGame.Common.Message.CommitPlayResponse as CommitPlayResponse
import BoardGame.Common.Message.MachinePlayResponse (MachinePlayResponse, MachinePlayResponse(MachinePlayResponse))
import qualified BoardGame.Common.Message.MachinePlayResponse as MachinePlayResponse

import qualified BoardGame.Server.Service.GameDao as GameDao
import qualified BoardGame.Server.Web.GameEndPoint as GameEndPoint
import qualified BoardGame.Util.TestUtil as TestUtil
import qualified Bolour.Util.SpecUtil as SpecUtil
import BoardGame.Server.Domain.GameEnv (GameEnv, GameEnv(GameEnv))
import qualified BoardGame.Server.Domain.GameEnv as GameEnv

import qualified Bolour.Util.PersistRunner as PersistRunner
import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig), DeployEnv(..))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig

import BoardGame.Server.Domain.GameEnv (GameEnv(GameEnv))
import Bolour.Util.WaiUtil
import qualified BoardGame.Client.GameClient as Client
import qualified BoardGame.Server.Domain.WordDictionary as Dict
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified BoardGame.Server.Domain.DictionaryCache as DictCache
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType


-- TODO. Start the server within the test - just copy main and test against it.
-- TODO. Need to shut down the server.

-- First we test against an external server.
-- In this first version the server has to be running for the test to succeed.

-- TODO. How to access the values returned by beforeAll within the test.

testConfigPath = "test-data/test-config.yml"

getGameEnv :: IO GameEnv
getGameEnv = do
  serverConfig <- ServerConfig.getServerConfig $ Just testConfigPath
  let ServerConfig {maxActiveGames, dbConfig} = serverConfig
  -- let serverConfig = ServerConfig.defaultServerConfig
      -- ServerConfig {maxActiveGames, dbConfig} = serverConfig
  connectionProvider <- PersistRunner.mkConnectionProvider dbConfig
  GameDao.migrateDb connectionProvider
  GameDao.cleanupDb connectionProvider
  cache <- GameCache.mkGameCache maxActiveGames
  dictionaryCache <- DictCache.mkCache "" 100
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
params = GameParams dimension 12 Dict.defaultLanguageCode thePlayer pieceProviderType
playerJohn = Player thePlayer

pointValues :: [[Int]]
pointValues = replicate dimension $ replicate dimension 1

centerGridPoint = Point center center

centerGridPiece :: Char -> IO GridPiece
centerGridPiece value = do
  piece <- Piece.mkPiece value
  return $ GridValue piece centerGridPoint

-- TODO. End duplicated

spec :: Spec
spec = beforeAll startApp $ afterAll endWaiApp $
  describe "start a game and make a player play and a machine play" $
    it "start a game and make a player play and a machine play" $ \(_, baseUrl) -> do
      (threadId, baseUrl) <- startApp
      initTest
      manager <- mkManager
      eitherMaybeUnit <- runExceptT (Client.addPlayer playerJohn manager baseUrl)

      uPieces <- sequence [Piece.mkPiece 'B', Piece.mkPiece 'E', Piece.mkPiece 'T'] -- Allow the word 'BET'
      mPieces <- sequence [Piece.mkPiece 'S', Piece.mkPiece 'T', Piece.mkPiece 'Z'] -- Allow the word 'SET' across.

      (StartGameResponse.StartGameResponse {gameId, trayPieces, gridPieces}) <- SpecUtil.satisfiesRight
        =<< runExceptT (Client.startGame (StartGameRequest params [] uPieces mPieces pointValues) manager baseUrl)

--       let GridValue {value = piece, point = centerPoint} =
--             fromJust $ find (\gridPiece -> GridPiece.gridLetter gridPiece == 'E') gridPieces
--           Point {row, col} = centerPoint

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
  GameDao.cleanupDb connectionProvider
  return ()

mkManager :: IO Manager
mkManager = newManager defaultManagerSettings

