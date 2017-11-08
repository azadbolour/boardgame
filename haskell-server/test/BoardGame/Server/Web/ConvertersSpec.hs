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
import BoardGame.Server.Web.Converters
import Bolour.Util.SpecUtil (satisfiesRight)
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
import qualified BoardGame.Server.Domain.PieceGenerator as PieceGenerator
-- import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary, LanguageDictionary(LanguageDictionary))

-- dictionary :: LanguageDictionary
-- dictionary = LanguageDictionary "en" [] (const True)

dim = 9
mid = dim `div` 2

spec :: Spec
spec = do
  describe "convert game to game dto and back" $
    it "game to dto" $ do
      let playerName = "You"
      let params = GameParams dim dim 12 Dict.defaultLanguageCode playerName
          pieceGenerator = PieceGenerator.mkCyclicPieceGenerator "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      let gridPiece = GridValue (Piece 'E' "idE") (Point mid mid)
      game <- satisfiesRight =<< runExceptT (Game.mkInitialGame params pieceGenerator [gridPiece] [] [] playerName)
      let dto = toDto game
      let brd = Game.board game
      length (Board.getGridPieces brd) `shouldBe` length (GameDto.gridPieces dto)
      let GridValue.GridValue {value = piece, point} = head (GameDto.gridPieces dto)
      let Point.Point {row} = point
      row `shouldBe` mid
  describe "convert game dto to game" $
    it "dto to game" $ do
      let playerName = "You"
          gridPieceA = GridValue (Piece 'A' "idA") (Point 4 5)
          gridPieceB = GridValue (Piece 'B' "idB") (Point 7 8)
          gridPieces = [gridPieceA, gridPieceB]
          pieceC = Piece 'C' "idC"
          pieceD = Piece 'D' "idD"
          pieceE = Piece 'E' "idE"
          trayPieces = [pieceC, pieceD, pieceD]
          dto = GameDto "id1" (GameParams 10 20 5 Dict.defaultLanguageCode playerName) gridPieces trayPieces
          game = toEntity dto
          gameBoard = Game.board game
          Tray size gameTrayPieces = Game.trays game !! userIndex
      Game.gameId game `shouldBe` GameDto.gameId dto
      length (Board.getGridPieces gameBoard) `shouldBe` length (GameDto.gridPieces dto)
      length gameTrayPieces `shouldBe` 3
      let Piece pieceValue pieceId = head gameTrayPieces
      pieceValue `shouldBe` 'C'



