--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Common.Domain.GridPiece (
    GridPiece
  , gridLetter
  , isEmpty
  ) where

import BoardGame.Common.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece

-- | A piece located on a grid.
type GridPiece = GridValue Piece

gridLetter :: GridPiece -> Char
gridLetter GridValue {value = piece} = Piece.value piece

isEmpty :: GridPiece -> Bool
isEmpty GridValue {value = piece} = Piece.isEmpty piece


