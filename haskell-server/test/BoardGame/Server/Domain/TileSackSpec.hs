--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.TileSackSpec where

import Test.Hspec
import BoardGame.Common.Domain.PieceGeneratorType (PieceGeneratorType, PieceGeneratorType(Random, Cyclic))
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Server.Domain.TileSack as TileSack
import BoardGame.Server.Domain.TileSack (TileSack, TileSack(RandomTileSack))

spec :: Spec
spec = do
  describe "Tile Sack" $ do
    it "has expected tiles" $ do
       let (sack @ RandomTileSack {initial, current}) = TileSack.mkDefaultPieceGen Random 15
       (TileSack.length' sack) `shouldSatisfy` (== 98)
       print $ Piece.value <$> initial


