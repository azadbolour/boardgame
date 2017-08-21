--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Common.Domain.GridPiece (
  GridPiece
  ) where

import BoardGame.Common.Domain.GridValue
import BoardGame.Common.Domain.Piece

-- | A piece located on a grid.
type GridPiece = GridValue Piece


