--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Web.GameEndPointSpec (
    spec
  ) where

import Data.Char (isUpper)
import Data.Maybe (fromJust)
import Data.List
import Test.Hspec
import Control.Monad.Trans.Except (runExceptT)
import Bolour.Util.SpecUtil (satisfiesRight)
import BoardGame.Common.Message.GameDto (GameDto(GameDto))
-- import BoardGame.Common.Message.StartGameRequest (StartGameRequest(StartGameRequest))
import qualified BoardGame.Common.Message.GameDto as GameDto(GameDto(..))
import BoardGame.Server.Domain.Play (Play, Play(Play))
import qualified BoardGame.Server.Domain.Play as Play
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import BoardGame.Common.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import qualified BoardGame.Common.Domain.GridPiece as GridPiece

import BoardGame.Server.Web.GameEndPoint (
    commitPlayHandler
  , machinePlayHandler
  , swapPieceHandler
  )
import BoardGame.Util.TestUtil (mkInitialPlayPieces)
import qualified BoardGame.Server.Web.WebTestFixtures as Fixtures (
      makePlayer
    , makeGame
    , thePlayer
    , gameParams
    , initTest
    , centerGridPiece
    , testDimension
    , testTrayCapacity
  )

-- TODO. Annotate spec do statements with the demystified type of their monad.
-- TODO. Factor out common test functions to a base type class.

-- TODO. Test with games of dimension 1 as a boundary case.

spec :: Spec
spec = do
  describe "start a game" $
    it "starts game" $
      do
        env <- Fixtures.initTest
        Fixtures.makePlayer env Fixtures.thePlayer
        gameDto <- Fixtures.makeGame env Fixtures.gameParams [] [] []
        length (GameDto.trayPieces gameDto) `shouldSatisfy` (== Fixtures.testTrayCapacity)

  describe "commits a play" $
    it "commit a play" $
      do
        env <- Fixtures.initTest
        Fixtures.makePlayer env Fixtures.thePlayer
        uPieces <- sequence [Piece.mkPiece 'B', Piece.mkPiece 'E', Piece.mkPiece 'T'] -- Allow the word 'BET'
        mPieces <- sequence [Piece.mkPiece 'S', Piece.mkPiece 'T', Piece.mkPiece 'Z'] -- Allow the word 'SET' across.
        GameDto {gameId, gameParams, gridPieces, trayPieces}
          <- Fixtures.makeGame env Fixtures.gameParams [] uPieces mPieces
--         let GridValue {value = piece, point = centerPoint} =
--               fromJust $ find (\gridPiece -> GridPiece.gridLetter gridPiece == 'E') gridPieces
--             Point {row, col} = centerPoint

        let pc0:pc1:pc2:_ = uPieces
            center = Fixtures.testDimension `div` 2
            playPieces = [
                PlayPiece pc0 (Point center (center - 1)) True
              , PlayPiece pc1 (Point center center) True
              , PlayPiece pc2 (Point center (center + 1)) True
              ]

        replacements <- satisfiesRight
          =<< runExceptT (commitPlayHandler env gameId playPieces)
        length replacements `shouldBe` 3

  describe "make machine play" $
    it "make machine play" $
      do
        env <- Fixtures.initTest
        Fixtures.makePlayer env Fixtures.thePlayer
        gameDto <- Fixtures.makeGame env Fixtures.gameParams [] [] []
        wordPlayPieces <- satisfiesRight
          =<< runExceptT (machinePlayHandler env (GameDto.gameId gameDto))
        let word = Play.playToWord $ Play wordPlayPieces
        length word `shouldSatisfy` (> 1)
  describe "swap a piece" $
    it "swap a piece" $
      do
        env <- Fixtures.initTest
        Fixtures.makePlayer env Fixtures.thePlayer
        (GameDto {gameId, trayPieces}) <- Fixtures.makeGame env Fixtures.gameParams [] [] []
        let piece = head trayPieces
        (Piece {value}) <- satisfiesRight
          =<< runExceptT (swapPieceHandler env gameId piece)
        value `shouldSatisfy` isUpper


