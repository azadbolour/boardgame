module BoardGame.Server.Domain.TileSack (
    TileSack, TileSack(RandomTileSack, CyclicTileSack)
  , next
  , pieceGeneratorType
  , mkDefaultPieceGen
  )
  where

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.PieceGeneratorType as PieceGeneratorType
import BoardGame.Common.Domain.PieceGeneratorType
import Bolour.Util.MiscUtil (IOEither)
import BoardGame.Server.Domain.GameError (GameError)

-- The piece generator types are closed in this implementation.
-- TODO. Would be nice to have an open piece generator implementation model.
-- So that new implementations of piece generator do not affect existing code.
-- What is the Haskell way of doing that?

-- | Piece generator.
--   Included in the common package to allow client tests
--   to generate pieces consistently with the server.
--   The string used in the cyclic generator has to be infinite.
data TileSack = RandomTileSack Integer | CyclicTileSack Integer String

isEmpty :: TileSack -> Bool
isEmpty sack = False

isFull :: TileSack -> Bool
isFull sack = False

length :: TileSack -> Int
length sack = maxBound :: Int

take :: TileSack -> IOEither GameError (Piece, TileSack)
take sack = Right <$> next sack

-- TODO. Better way to disambiguate?
take' = BoardGame.Server.Domain.TileSack.take

takeAvailableTilesToList :: TileSack -> [Piece] -> Int -> IO ([Piece], TileSack)
takeAvailableTilesToList sack list n =
  if n == 0 || isEmpty sack
    then return (list, sack)
    else do
      Right (piece, sack1) <- take' sack -- Cannot fail if sack is non-empty.
      (pieces, sack2) <- takeAvailableTilesToList sack1 (piece:list) (n - 1)
      return (pieces, sack2)

takeAvailableTiles :: TileSack -> Int -> IO ([Piece], TileSack)
takeAvailableTiles sack max = takeAvailableTilesToList sack [] max

give :: TileSack -> Piece -> Either GameError TileSack
give sack piece = Right sack

next :: TileSack -> IO (Piece, TileSack)
next (RandomTileSack count) = do
  let count' = count + 1
  piece <- Piece.mkRandomPieceForId (show count')
  return (piece, RandomTileSack count')
next (CyclicTileSack count cycler) = do
  let count' = count + 1
      piece = Piece (head cycler) (show count')
  return (piece, CyclicTileSack count' (drop 1 cycler))

pieceGeneratorType :: TileSack -> PieceGeneratorType
pieceGeneratorType (RandomTileSack _) = PieceGeneratorType.Random
pieceGeneratorType (CyclicTileSack _ _) = PieceGeneratorType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultPieceGen :: PieceGeneratorType -> TileSack
mkDefaultPieceGen PieceGeneratorType.Random = RandomTileSack 0
mkDefaultPieceGen PieceGeneratorType.Cyclic = CyclicTileSack 0 (cycle caps)

