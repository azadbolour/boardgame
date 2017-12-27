module BoardGame.Common.Domain.TileSack (
    TileSack, TileSack(RandomTileSack, CyclicTileSack)
  , next
  , pieceOf
  , pieceGeneratorType
  , mkDefaultPieceGen
  )
  where

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.PieceGeneratorType as PieceGeneratorType
import BoardGame.Common.Domain.PieceGeneratorType

-- The piece generator types are closed in this implementation.
-- TODO. Would be nice to have an open piece generator implementation model.
-- So that new implementations of piece generator do not affect existing code.
-- What is the Haskell way of doing that?

-- | Piece generator.
--   Included in the common package to allow client tests
--   to generate pieces consistently with the server.
--   The string used in the cyclic generator has to be infinite.
data TileSack = RandomTileSack Integer | CyclicTileSack Integer String

next :: TileSack -> IO (Piece, TileSack)
next (RandomTileSack count) = do
  let count' = count + 1
  piece <- Piece.mkRandomPieceForId (show count')
  return (piece, RandomTileSack count')
next (CyclicTileSack count cycler) = do
  let count' = count + 1
      piece = Piece (head cycler) (show count')
  return (piece, CyclicTileSack count' (drop 1 cycler))

pieceOf :: TileSack -> Char -> IO (Piece, TileSack)
pieceOf (RandomTileSack count) letter = do
  let count' = count + 1
      piece = Piece letter (show count')
  return (piece, RandomTileSack count')
pieceOf (CyclicTileSack count cycler) letter = do
  let count' = count + 1
      piece = Piece letter (show count')
  return (piece, CyclicTileSack count' cycler)

pieceGeneratorType :: TileSack -> PieceGeneratorType
pieceGeneratorType (RandomTileSack _) = PieceGeneratorType.Random
pieceGeneratorType (CyclicTileSack _ _) = PieceGeneratorType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultPieceGen :: PieceGeneratorType -> TileSack
mkDefaultPieceGen PieceGeneratorType.Random = RandomTileSack 0
mkDefaultPieceGen PieceGeneratorType.Cyclic = CyclicTileSack 0 (cycle caps)

