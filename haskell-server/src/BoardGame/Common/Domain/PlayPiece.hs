--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Common.Domain.PlayPiece (
    PlayPiece(..)
  , MoveInfo
  , playPiecesToWord
  , getGridPiece
  , toMoveInfo
)
where

import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)
import Bolour.Plane.Domain.Point (Point)
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.PiecePoint (PiecePoint, PiecePoint(PiecePoint))
import qualified BoardGame.Common.Domain.Piece as Piece

-- | A piece that forms part of the word formed in a play.
data PlayPiece = PlayPiece {
    piece :: Piece -- ^ The piece in play or being played.
  , point :: Point -- ^ The position of the piece in teh board.
  , moved :: Bool -- ^ True iff the piece is being played (versus having been on the board already).
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON PlayPiece
instance ToJSON PlayPiece

type Moved = Bool
type Letter = Char
type MoveInfo = (Letter, Point, Moved)

toMoveInfo :: PlayPiece -> MoveInfo
toMoveInfo (PlayPiece { piece, point, moved }) = (Piece.value piece, point, moved)

-- TODO. Change name to piecePoint.
-- | Convenience function to get the play piece's location on the board.
getGridPiece :: PlayPiece -> PiecePoint
getGridPiece PlayPiece {piece, point} = PiecePoint piece point

-- | Get the word spelled out by the pieces in a list of play pieces.
playPiecesToWord :: [PlayPiece] -> String
playPiecesToWord playPieces = (Piece.value . piece) <$> playPieces



