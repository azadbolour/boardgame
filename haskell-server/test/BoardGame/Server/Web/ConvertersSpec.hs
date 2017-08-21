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
import qualified BoardGame.Server.Domain.LanguageDictionary as Dict
import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary, LanguageDictionary(LanguageDictionary))

dictionary :: LanguageDictionary
dictionary = LanguageDictionary "en" [] (const True)

spec :: Spec
spec = do
  describe "convert game to game dto and back" $
    it "game to dto" $ do
      let playerName = "You"
      let params = GameParams 9 9 12 Dict.defaultLanguageCode playerName
      game <- satisfiesRight =<< runExceptT (Game.mkInitialGame params [] [] [] playerName dictionary)
      let dto = toDto game
      let brd = Game.board game
      GameDto.height dto `shouldBe` Board.height brd
      length (Board.getGridPieces brd) `shouldBe` length (GameDto.gridPieces dto)
      let GridValue.GridValue {value = piece, point} = head (GameDto.gridPieces dto)
      let Point.Point {row} = point
      row `shouldBe` (9 `div` 2)
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
          dto = GameDto "id1" Dict.defaultLanguageCode 10 20 5 gridPieces trayPieces playerName
          game = toEntity dto
          gameBoard = Game.board game
          Tray size gameTrayPieces = Game.trays game !! userIndex
      Game.gameId game `shouldBe` GameDto.gameId dto
      length (Board.getGridPieces gameBoard) `shouldBe` length (GameDto.gridPieces dto)
      length gameTrayPieces `shouldBe` 3
      let Piece pieceValue pieceId = head gameTrayPieces
      pieceValue `shouldBe` 'C'



