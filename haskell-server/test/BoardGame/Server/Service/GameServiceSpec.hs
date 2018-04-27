--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.GameServiceSpec (
    spec
  ) where

import Test.Hspec
import Data.Char (isUpper, toUpper)
import Data.List
import Control.Monad.Except (ExceptT, runExceptT)
import Control.Monad.Reader (runReaderT)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Log (runLoggingT)

import qualified Bolour.Util.PersistRunner as PersistRunner
import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig), DeployEnv(..))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig
import BoardGame.Common.Domain.Player(Player, Player(Player))
import BoardGame.Common.Domain.Piece (Piece(Piece))
import Bolour.Plane.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified Bolour.Plane.Domain.GridValue as GridValue
import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Server.Domain.GameCache as GameCache
import BoardGame.Server.Service.GameDao (cleanupDb)
import BoardGame.Server.Domain.GameError
import BoardGame.Server.Domain.Game (Game(Game))
-- import BoardGame.Server.Domain.Play (Play(Play))
import BoardGame.Server.Domain.GameEnv (GameEnv, GameEnv(GameEnv))
import BoardGame.Server.Service.GameTransformerStack

-- import qualified BoardGame.Server.Domain.Play as Play (playToWord)
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Server.Domain.Tray as Tray
import qualified BoardGame.Server.Domain.Game as Game
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Service.GameService (
    addPlayerService
  , commitPlayService
  , startGameService
  , machinePlayService
  , swapPieceService
  , getGamePlayDetailsService
  )
-- TODO. Should not depend on higher level module.
import BoardGame.Util.TestUtil (mkInitialPlayPieces)
import qualified BoardGame.Server.Service.ServiceTestFixtures as Fixtures
import qualified Bolour.Language.Domain.DictionaryCache as DictCache

printx :: String -> ExceptT GameError IO ()
printx s = do
  liftIO $ print s
  return ()

-- TODO. Annotate spec do statements with the demystified type of their monad.
-- TODO. Factor out common test functions to a base type class.

-- TODO. Test with games of dimension 1 as a boundary case.

runner :: GameEnv -> GameTransformerStack a -> IO (Either GameError a)
runner env stack = runExceptT $ flip runLoggingT printx $ runReaderT stack env

-- TODO. How to catch Left - print error and return gracefully.
runner' env stack = do
  Right val <- runner env stack
  return val

runner'' :: GameTransformerStack a -> IO a
runner'' stack = do
  env <- Fixtures.initTest
  runner' env stack

spec :: Spec
spec = do
  describe "start a game" $
    it "starts game" $
      do -- IO
        userTray <- runner'' $ do -- GameTransformerStack
          addPlayerService $ Player Fixtures.thePlayer
          Game {trays} <- startGameService Fixtures.gameParams [] [] [] []
          return $ trays !! 0
        length (Tray.pieces userTray) `shouldSatisfy` (== Fixtures.testTrayCapacity)

  describe "commits a play" $
    it "commit a play" $
      do -- IO
        let uPieces = [Piece 'B' "1", Piece 'E' "2", Piece 'T' "3"] -- Allow the word 'BET'
            mPieces = [Piece 'S' "4", Piece 'T' "5", Piece 'Z' "6"] -- Allow the word 'SET' across.

        (miniState, replacementPieces, deadPieces) <- runner'' $ do -- GameTransformerStack
          addPlayerService $ Player Fixtures.thePlayer
          Game {gameId, board, trays} <- startGameService Fixtures.gameParams [] uPieces mPieces []
          let pc0:pc1:pc2:_ = uPieces
              center = Fixtures.testDimension `div` 2
              playPieces = [
                  PlayPiece pc0 (Point center (center - 1)) True
                , PlayPiece pc1 (Point center center) True
                , PlayPiece pc2 (Point center (center + 1)) True
                ]
          commitPlayService gameId playPieces -- refills
        length replacementPieces `shouldBe` 3

  describe "make machine play" $
    it "make machine play" $
      do -- IO
        word <- runner'' $ do
          addPlayerService $ Player Fixtures.thePlayer
          Game {gameId} <- startGameService Fixtures.gameParams [] [] [] []
          (miniState, playedPieces, deadPieces) <- machinePlayService gameId
          let word = PlayPiece.playPiecesToWord playedPieces
          return word
        print word
        length word `shouldSatisfy` (> 1)

  describe "swap a piece" $
    it "swap a piece" $
      do
        value <- runner'' $ do
          addPlayerService $ Player Fixtures.thePlayer
          Game {gameId, trays} <- startGameService Fixtures.gameParams [] [] [] []
          let userTray = trays !! 0
              piece = head (Tray.pieces userTray)
          -- TODO satisfiesRight
          (miniState, Piece {value}) <- swapPieceService gameId piece
          return value
        value `shouldSatisfy` isUpper
