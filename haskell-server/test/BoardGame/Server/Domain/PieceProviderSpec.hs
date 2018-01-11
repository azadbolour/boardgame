--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.PieceProviderSpec where

import Test.Hspec
import BoardGame.Common.Domain.PieceProviderType (PieceProviderType, PieceProviderType(Random, Cyclic))
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import BoardGame.Server.Domain.PieceProvider (PieceProvider, PieceProvider(RandomPieceProvider))

spec :: Spec
spec = do
  describe "Tile Sack" $ do
    it "has expected tiles" $ do
       let (sack @ RandomPieceProvider {initial, current}) = PieceProvider.mkDefaultPieceGen Random 15
       (PieceProvider.length' sack) `shouldSatisfy` (== 98)
       print $ Piece.value <$> initial


