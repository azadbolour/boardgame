--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Integration.JsonSpec (
    spec
  ) where

import Test.Hspec
import Data.Aeson
import Control.Monad.Trans.Except (runExceptT)
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(GameParams))
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.Game (Game, Game(Game))
import qualified BoardGame.Server.Domain.Game as Game
import qualified Bolour.Util.SpecUtil as SpecUtil
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
import qualified BoardGame.Server.Domain.PieceGenerator as PieceGenerator

spec :: Spec

name = "You"
params :: GameParams
params = GameParams 9 9 12 Dict.defaultLanguageCode name

game :: IO Game
game = do
  let pieceGenerator = PieceGenerator.mkCyclicPieceGenerator "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  SpecUtil.satisfiesRight =<< runExceptT (Game.mkInitialGame params pieceGenerator [] [] [] name)

spec = do
  describe "json for game params" $ do
    it "convert to/from json" $ do
      piece <- Piece.mkPiece 'T'
      let encoded = encode (params, [piece])
      print encoded
      let decoded = decode encoded :: Maybe (GameParams, [Piece])
      print decoded




