--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}

module BoardGame.Integration.GameClientSpec (
    spec
  ) where

import Data.Char (isUpper, toUpper)
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
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Common.Domain.Point (Point(Point))
-- import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.GameParams (GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Common.Domain.Player (Player(Player))
import qualified BoardGame.Common.Message.GameDto as GameDto
import qualified BoardGame.Server.Service.GameDao as GameDao
import qualified BoardGame.Server.Web.GameEndPoint as GameEndPoint
import qualified BoardGame.Util.TestUtil as TestUtil
import qualified Bolour.Util.SpecUtil as SpecUtil
import BoardGame.Server.Domain.GameConfig (Config(Config))
-- import qualified BoardGame.Server.Domain.GameConfig as Env
import qualified BoardGame.Server.Domain.GameConfig as Config
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters
import BoardGame.Server.Domain.GameEnv (GameEnv(GameEnv))
import BoardGame.Server.Domain.IndexedLanguageDictionary (IndexedLanguageDictionary)
import Bolour.Util.WaiUtil
import qualified Bolour.Util.DbUtil as DbUtil
import qualified BoardGame.Client.GameClient as Client
import qualified BoardGame.Server.Domain.LanguageDictionary as Dict
import qualified BoardGame.Server.Domain.GameCache as GameCache
-- import qualified Bolour.Util.StaticTextFileCache as FileCache
import qualified BoardGame.Server.Domain.DictionaryCache as DictCache
import BoardGame.Server.Domain.DictionaryCache (DictionaryCache)

-- TODO. Start the server within the test - just copy main and test against it.
-- TODO. Need to shut down the server.

-- First we test against an external server.
-- In this first version the server has to be running for the test to succeed.

-- TODO. How to access the values returned by beforeAll within the test.

config :: IO Config
config = do
  -- TODO. Use getServerParameters and provide a config file for test.
  let serverParameters = Config.defaultServerParameters
      ServerParameters.ServerParameters {maxActiveGames} = serverParameters
  thePool <- DbUtil.makePool serverParameters
  Config.mkConfig serverParameters thePool

  -- Config.mkConfig Env.Test thePool

startApp :: IO (ThreadId, BaseUrl)
startApp = do
  let serverParameters = Config.defaultServerParameters
      ServerParameters.ServerParameters {maxActiveGames} = serverParameters
  cache <- GameCache.mkGameCache maxActiveGames
  -- dictionaryCache <- FileCache.mkCache 100 (toUpper <$>)
  (dictionaryCache :: DictionaryCache IndexedLanguageDictionary) <- DictCache.mkCache "" 100
  conf <- config
  let gameEnv = GameEnv conf cache dictionaryCache
  let gameApp = GameEndPoint.mkGameApp gameEnv
  startWaiApp gameApp

-- TODO. Duplicated in WebTestFixtures. Unify into single fixture module.

thePlayer = "You"
params = GameParams 9 9 12 Dict.defaultLanguageCode thePlayer
playerJohn = Player thePlayer

centerGridPoint =
  let GameParams.GameParams {height, width, trayCapacity, playerName} = params
  in Point (height `div`2) (width `div` 2)

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
      gridPiece <- centerGridPiece 'E'
      includeUserPieces <- sequence [Piece.mkPiece 'B', Piece.mkPiece 'T'] -- Allow the word 'BET'
      (GameDto.GameDto {gameId, trayPieces, gridPieces}) <- SpecUtil.satisfiesRight
        =<< runExceptT (Client.startGame (params, [gridPiece], includeUserPieces, []) manager baseUrl)
      let playPieces = TestUtil.mkInitialPlayPieces (head gridPieces) trayPieces
      replacements <- SpecUtil.satisfiesRight =<< runExceptT (Client.commitPlay gameId playPieces manager baseUrl)
      length replacements `shouldBe` 2
      wordPlayPieces <- SpecUtil.satisfiesRight
        =<< runExceptT (Client.machinePlay gameId manager baseUrl)
      print $ PlayPiece.playPiecesToWord wordPlayPieces
      let piece = last trayPieces
      (Piece.Piece {value}) <- SpecUtil.satisfiesRight
         =<< runExceptT (Client.swapPiece gameId piece manager baseUrl)
      value `shouldSatisfy` isUpper
      killThread threadId

initTest :: IO ()
initTest = do
  cfg <- config
  GameDao.cleanupDb cfg
  return ()

mkManager :: IO Manager
mkManager = newManager defaultManagerSettings

