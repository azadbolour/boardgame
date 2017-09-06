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
import Test.Hspec
import Control.Monad.Trans.Except (runExceptT)
import Bolour.Util.SpecUtil (satisfiesRight)
import BoardGame.Common.Message.GameDto (GameDto(GameDto))
import qualified BoardGame.Common.Message.GameDto as GameDto(GameDto(..))
import BoardGame.Server.Domain.Play (Play, Play(Play))
import qualified BoardGame.Server.Domain.Play as Play
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
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
        length (GameDto.trayPieces gameDto) `shouldSatisfy` (== 12)

  describe "commits a play" $
    it "commit a play" $
      do
        env <- Fixtures.initTest
        Fixtures.makePlayer env Fixtures.thePlayer
        gridPiece <- Fixtures.centerGridPiece 'E'
        includeUserPieces <- sequence [Piece.mkPiece 'B', Piece.mkPiece 'T'] -- Allow the word 'BET'
        GameDto {gameId, height, width, trayCapacity, gridPieces, trayPieces}
          <- Fixtures.makeGame env Fixtures.gameParams [gridPiece] includeUserPieces []
        let playPieces = mkInitialPlayPieces (head gridPieces) trayPieces
        replacements <- satisfiesRight
          =<< runExceptT (commitPlayHandler env gameId playPieces)
        length replacements `shouldBe` 2

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


