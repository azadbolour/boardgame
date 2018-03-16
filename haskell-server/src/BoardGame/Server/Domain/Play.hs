--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.Play (
    Play(..)
  , playToWord
  , movesOfPlay
)
where

import BoardGame.Common.Domain.GridPiece
import BoardGame.Common.Domain.PlayPiece (PlayPiece)

import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece

type Moved = Bool

-- | A word play including all the word's letters, their locations, and whether
--   formed a move in the play.
data Play = Play {
    -- | The pieces, their locations, and whether moved or existing,
    --   in the line segment of this play.
    playPieces :: [PlayPiece]
}
  deriving (Eq, Show)

playToWord :: Play -> String
playToWord (Play playPieces) = PlayPiece.playPiecesToWord playPieces

movesOfPlay :: Play -> [GridPiece]
movesOfPlay Play {playPieces} =
  let movedPlayPieces = filter (\x -> PlayPiece.moved x) playPieces
  in PlayPiece.getGridPiece <$> movedPlayPieces


