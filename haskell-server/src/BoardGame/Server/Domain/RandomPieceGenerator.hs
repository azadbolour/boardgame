--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}


module BoardGame.Server.Domain.RandomPieceGenerator (
    RandomPieceGenerator
  , mkRandomPieceGenerator
  ) where

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.PieceGenerator

data RandomPieceGenerator = RandomPieceGenerator {
    count :: Integer
}

mkRandomPieceGenerator :: RandomPieceGenerator
mkRandomPieceGenerator = RandomPieceGenerator 0

-- TODO. Move the random generation machinery from Piece to RandomPieceGenerator.
instance PieceGenerator RandomPieceGenerator where
  next RandomPieceGenerator {count} = do
    let count' = count + 1
    piece <- Piece.mkRandomPieceForId (show count')
    return (piece, RandomPieceGenerator count')