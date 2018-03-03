--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Web.ConvertersSpec where

import Test.Hspec
import Control.Monad.Trans.Except (runExceptT)
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(GameParams))
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import BoardGame.Common.Domain.Player (userIndex)
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
import Bolour.Plane.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified Bolour.Plane.Domain.GridValue as GridValue
import BoardGame.Common.Message.StartGameResponse as StartGameResponse
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Web.Converters(gameToStartGameResponse)
import Bolour.Util.SpecUtil (satisfiesRight)
import qualified Bolour.Language.Domain.WordDictionary as Dict
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType

dim = 9
mid = dim `div` 2
thePlayer = "You"

pointValues :: [[Int]]
pointValues = replicate dim $ replicate dim 1

pieceProviderType = PieceProviderType.Cyclic
params = GameParams dim 12 Dict.defaultLanguageCode thePlayer pieceProviderType
tileSack = PieceProvider.mkDefaultPieceProvider PieceProviderType.Cyclic dim

spec :: Spec
spec = do
  describe "convert game to game dto" $
    it "game to dto" $ do
      let playerName = "You"
      let gridPiece = GridValue (Piece 'E' "idE") (Point mid mid)
      game <- satisfiesRight =<< runExceptT (Game.mkInitialGame params tileSack [gridPiece] [] [] pointValues playerName)
      let response = gameToStartGameResponse game
      let brd = Game.board game
      length (Board.getGridPieces brd) `shouldBe` length (StartGameResponse.gridPieces response)
      let GridValue.GridValue {value = piece, point} = head (StartGameResponse.gridPieces response)
      let Point.Point {row} = point
      row `shouldBe` mid



