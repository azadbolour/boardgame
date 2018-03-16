--
-- Copyright 2017-2018 Azad Bolour
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
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.Game (Game, Game(Game))
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.GameError
import qualified Bolour.Util.SpecUtil as SpecUtil
import qualified Bolour.Language.Domain.WordDictionary as Dict
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType

spec :: Spec

name = "You"
dim = 9

pieceProviderType = PieceProviderType.Cyclic
params :: GameParams
params = GameParams dim 12 Dict.defaultLanguageCode name pieceProviderType
tileSack = PieceProvider.mkDefaultPieceProvider PieceProviderType.Cyclic dim

pointValues :: [[Int]]
pointValues = replicate dim $ replicate dim 1


game :: IO Game
game = do
  SpecUtil.satisfiesRight =<< runExceptT (Game.mkInitialGame params tileSack [] [] [] pointValues name)

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




