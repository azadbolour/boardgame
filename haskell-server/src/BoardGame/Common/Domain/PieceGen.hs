module BoardGame.Common.Domain.PieceGen (
    PieceGen, PieceGen(RandomGen, CyclicGen)
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
data PieceGen = RandomGen Integer | CyclicGen Integer String

next :: PieceGen -> IO (Piece, PieceGen)
next (RandomGen count) = do
  let count' = count + 1
  piece <- Piece.mkRandomPieceForId (show count')
  return (piece, RandomGen count')
next (CyclicGen count cycler) = do
  let count' = count + 1
      piece = Piece (head cycler) (show count')
  return (piece, CyclicGen count' (drop 1 cycler))

pieceOf :: PieceGen -> Char -> IO (Piece, PieceGen)
pieceOf (RandomGen count) letter = do
  let count' = count + 1
      piece = Piece letter (show count')
  return (piece, RandomGen count')
pieceOf (CyclicGen count cycler) letter = do
  let count' = count + 1
      piece = Piece letter (show count')
  return (piece, CyclicGen count' cycler)

pieceGeneratorType :: PieceGen -> PieceGeneratorType
pieceGeneratorType (RandomGen _) = PieceGeneratorType.Random
pieceGeneratorType (CyclicGen _ _) = PieceGeneratorType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultPieceGen :: PieceGeneratorType -> PieceGen
mkDefaultPieceGen PieceGeneratorType.Random = RandomGen 0
mkDefaultPieceGen PieceGeneratorType.Cyclic = CyclicGen 0 (cycle caps)

