--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Service.NegativeGameServiceSpec (
    spec
  ) where

import Data.Char (toUpper)
import Test.Hspec
import Control.Monad.Except (ExceptT, runExceptT)
import Control.Monad.Reader (runReaderT)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Log (runLoggingT)

import BoardGame.Common.Domain.Player (Player, Player(Player))
import BoardGame.Common.Domain.GameParams (GameParams(..))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import qualified BoardGame.Common.Domain.Point as Point (Axis(..))
import Bolour.Util.DbUtil (makePool)
import BoardGame.Server.Domain.GameConfig (Config(..), DeployEnv(..))
import qualified BoardGame.Server.Domain.GameConfig as Config
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters
import BoardGame.Server.Service.GameDao (cleanupDb)
import BoardGame.Server.Domain.GameCache as GameCache
import BoardGame.Server.Domain.GameError (GameError)

import qualified BoardGame.Server.Service.GameService as GameService

import qualified BoardGame.Server.Domain.GameError as GameError
import BoardGame.Server.Domain.GameEnv (GameEnv, GameEnv(GameEnv))
import BoardGame.Server.Service.GameTransformerStack
import qualified Bolour.Util.StaticTextFileCache as FileCache

-- TODO. Should not depend on higher level module.
import BoardGame.Server.Web.WebTestFixtures (
      thePlayer
    , params
  )

printx :: String -> ExceptT GameError IO ()
printx s = do
  liftIO $ print s
  return ()

-- TODO. Duplicate code - see GameServiceSpec. Factor out.
initTest :: IO GameEnv -- TODO. Should be MonadIO m.
initTest = do
  let serverParameters = Config.defaultServerParameters -- TODO. Change to use test server parameters.
      ServerParameters.ServerParameters {maxActiveGames} = serverParameters
  thePool <- makePool serverParameters
  config <- Config.mkConfig serverParameters thePool
  cleanupDb config
  cache <- GameCache.mkGameCache maxActiveGames
  dictionaryCache <- FileCache.mkCache 100 (toUpper <$>)
  return $ GameEnv config cache dictionaryCache

runner :: GameEnv -> GameTransformerStack a -> IO (Either GameError a)
runner env stack = runExceptT $ flip runLoggingT printx $ runReaderT stack env

runR :: GameEnv -> GameTransformerStack a -> IO a
runR env stack = do
  Right val <- runner env stack
  return val

runL :: GameEnv -> GameTransformerStack a -> IO GameError
runL env stack = do
  Left error <- runner env stack
  return error

runR' :: GameTransformerStack a -> IO a
runR' stack = do
  env <- initTest
  runR env stack

runL' :: GameTransformerStack a -> IO GameError
runL' stack = do
  env <- initTest
  runL env stack



-- TODO. Annotate spec do statements with the demystified type of their monad.
-- TODO. Factor out common test functions to a base type class.

nonExistentPlayerName = "Mary"
paramsBadPlayer = params {playerName = nonExistentPlayerName}
nonAlphaNumPlayerName = "Mary-?"
paramsNonAlphaNumPlayer = params {playerName = nonAlphaNumPlayerName}
badDimension = -1
paramsBadDimension = params {height = badDimension}
paramsZeroWidth = params {width = 0}
badTrayCapacity = 0
paramsBadTrayCapacity = params {trayCapacity = badTrayCapacity}
-- TODO. 0 and 1 are also bad sizes.

spec :: Spec
spec = do
  describe "invalid data to start a game" $ do
    it "requires alphnumeric player names" $
      do
        error <- runL' $ GameService.addPlayerService $ Player nonAlphaNumPlayerName
        error `shouldBe` GameError.InvalidPlayerNameError nonAlphaNumPlayerName

    it "guards against non-existent player" $
      do
        runR' $ GameService.addPlayerService $ Player thePlayer
        error <- runL' $ GameService.startGameService paramsBadPlayer [] [] []
        error `shouldBe` GameError.MissingPlayerError nonExistentPlayerName

    it "disallows negative board dimensions" $
      do
        runR' $ GameService.addPlayerService $ Player thePlayer
        error <- runL' $ GameService.startGameService paramsBadDimension [] [] []
        error `shouldBe` GameError.InvalidDimensionError Point.Y badDimension

    it "disallows 0 board dimensions" $
      do
        runR' $ GameService.addPlayerService $ Player thePlayer
        error <- runL' $ GameService.startGameService paramsZeroWidth [] [] []
        error `shouldBe` GameError.InvalidDimensionError Point.X 0

    it "disallows trays with 0 capacity" $
      do
        runR' $ GameService.addPlayerService $ Player thePlayer
        error <- runL' $ GameService.startGameService paramsBadTrayCapacity [] [] []
        error `shouldBe` GameError.InvalidTrayCapacityError badTrayCapacity


