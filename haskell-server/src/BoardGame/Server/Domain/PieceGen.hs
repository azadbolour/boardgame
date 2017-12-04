module BoardGame.Server.Domain.PieceGen (
    PieceGen, PieceGen(RandomGen, CyclicGen)
  , next
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

-- String has to be infinite.
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

pieceGeneratorType :: PieceGen -> PieceGeneratorType
pieceGeneratorType (RandomGen _) = PieceGeneratorType.Random
pieceGeneratorType (CyclicGen _ _) = PieceGeneratorType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultPieceGen :: PieceGeneratorType -> PieceGen
mkDefaultPieceGen PieceGeneratorType.Random = RandomGen 0
mkDefaultPieceGen PieceGeneratorType.Cyclic = CyclicGen 0 (cycle caps)

