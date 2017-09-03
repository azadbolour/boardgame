--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.PieceGenerator (
    PieceGenerator(..)
  , CyclicPieceGenerator
  , mkCyclicPieceGenerator
  ) where

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece

class PieceGenerator gen where
  next :: gen -> IO (Piece, gen)

data CyclicPieceGenerator = CyclicPieceGenerator {
    count :: Integer
  , cycler :: String
}

mkCyclicPieceGenerator :: String -> CyclicPieceGenerator
mkCyclicPieceGenerator chars = CyclicPieceGenerator 0 $ cycle chars

instance PieceGenerator CyclicPieceGenerator where
  next CyclicPieceGenerator {count, cycler} = do
    let count' = count + 1
        piece = Piece (head cycler) (show count')
    return (piece, CyclicPieceGenerator count' (drop 1 cycler))
