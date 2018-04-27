--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Server.Service.PieceProviderSpec where

import Test.Hspec
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (ExceptT, runExceptT)
import Data.List

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import Bolour.Util.FrequencyDistribution (FrequencyDistribution(..))
import qualified Bolour.Util.FrequencyDistribution as FrequencyDistribution
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import BoardGame.Server.Domain.PieceProvider (PieceProvider(..))
import BoardGame.Server.Domain.GameError (GameError)

letterFrequencies = [
    ('A', 10),
    ('B', 20),
    ('C', 30),
    ('D', 40)
  ]

letterDistribution :: FrequencyDistribution Char
letterDistribution = FrequencyDistribution.mkFrequencyDistribution letterFrequencies

provider0 :: PieceProvider
provider0 = RandomPieceProvider 0 (FrequencyDistribution.randomValue letterDistribution)

makePiece :: PieceProvider -> ExceptT GameError IO (Piece, PieceProvider)
makePiece provider = PieceProvider.take provider

nextState :: IO (Piece, PieceProvider) -> IO (Piece, PieceProvider)
nextState ioPair = do
  (piece, provider) <- ioPair
  Right pair <- runExceptT $ makePiece provider
  return pair

spec :: Spec
spec =
  describe "for visual inspection of random piece generation" $
    it "generate random pieces and count the letters generated" $ do
      Right (piece, provider) <- runExceptT (PieceProvider.take provider0)
      pairs <- sequence $ take 100 $ iterate nextState (return (piece, provider))
      let pieces = fst <$> pairs
          letters = Piece.value <$> pieces
      print letters
      let groups = group $ sort letters
          counted = (\g -> (head g, length g)) <$> groups
      print counted





