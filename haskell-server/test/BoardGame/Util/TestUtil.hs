--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Util.TestUtil (
  mkInitialPlayPieces
  ) where

import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import BoardGame.Common.Domain.GridPiece (GridPiece)
-- import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point

mkInitialPlayPieces :: GridPiece -> [Piece] -> [PlayPiece]
mkInitialPlayPieces (centerBoardPiece @ GridValue.GridValue {value = piece, point}) trayPieces = playPieces where
  Point.Point {row, col} = point
  -- r = row $ point
  -- c = col $ point
  centerPlayPiece = PlayPiece piece point False
  leftPiece = trayPieces !! 0
  leftPlayPiece = PlayPiece leftPiece (Point row (col - 1)) True
  rightPiece = trayPieces !! 1
  rightPlayPiece = PlayPiece rightPiece (Point row (col + 1)) True
  playPieces = [leftPlayPiece, centerPlayPiece, rightPlayPiece]


