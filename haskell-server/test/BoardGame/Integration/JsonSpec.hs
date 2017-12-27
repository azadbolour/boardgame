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
import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.Game (Game, Game(Game))
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.GameError
import qualified Bolour.Util.SpecUtil as SpecUtil
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
import qualified BoardGame.Server.Domain.TileSack as TileSack
import qualified BoardGame.Common.Domain.PieceGeneratorType as PieceGeneratorType

spec :: Spec

name = "You"

pieceGeneratorType = PieceGeneratorType.Cyclic
params :: GameParams
params = GameParams 9 12 Dict.defaultLanguageCode name pieceGeneratorType
pieceGenerator = TileSack.mkDefaultPieceGen PieceGeneratorType.Cyclic

game :: IO Game
game = do
  SpecUtil.satisfiesRight =<< runExceptT (Game.mkInitialGame params pieceGenerator [] [] [] name)

spec = do
  describe "json for game data" $ do
    it "convert game params to/from json" $ do
      piece <- Piece.mkPiece 'T'
      let encoded = encode (params, [piece])
      print encoded
      let decoded = decode encoded :: Maybe (GameParams, [Piece])
      print decoded
    it "convert a game error to/from json" $ do
      let error = NonContiguousPlayError $ [Point 1 1]
      let encoded = encode error
      print encoded
      let decoded = decode encoded :: Maybe GameError
      print decoded




