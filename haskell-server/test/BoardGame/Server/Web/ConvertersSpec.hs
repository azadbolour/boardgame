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
import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Message.GameDto as GameDto
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Web.Converters(gameToDto)
import Bolour.Util.SpecUtil (satisfiesRight)
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
import qualified BoardGame.Common.Domain.PieceGen as PieceGen
import qualified BoardGame.Common.Domain.PieceGeneratorType as PieceGeneratorType

dim = 9
mid = dim `div` 2
thePlayer = "You"

pieceGeneratorType = PieceGeneratorType.Cyclic
params = GameParams dim dim 12 Dict.defaultLanguageCode thePlayer pieceGeneratorType
pieceGenerator = PieceGen.mkDefaultPieceGen PieceGeneratorType.Cyclic

spec :: Spec
spec = do
  describe "convert game to game dto" $
    it "game to dto" $ do
      let playerName = "You"
      let gridPiece = GridValue (Piece 'E' "idE") (Point mid mid)
      game <- satisfiesRight =<< runExceptT (Game.mkInitialGame params pieceGenerator [gridPiece] [] [] playerName)
      let dto = gameToDto game
      let brd = Game.board game
      length (Board.getGridPieces brd) `shouldBe` length (GameDto.gridPieces dto)
      let GridValue.GridValue {value = piece, point} = head (GameDto.gridPieces dto)
      let Point.Point {row} = point
      row `shouldBe` mid



