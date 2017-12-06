--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DeriveGeneric #-}

module BoardGame.Server.Domain.GameError (
    GameError(..)
  , ExceptGame
)
where

import GHC.Generics
import Data.Aeson
import Control.Monad.Except (ExceptT)

import BoardGame.Common.Domain.Point
import BoardGame.Common.Domain.Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)

-- TODO. Create a function gameErrorMessage :: GameError -> String
-- Default is encode error - can specialize for some.
data GameError =
  PositionOutOfBoundsError {
    axis :: Axis
  , range :: (Coordinate, Coordinate)
  , position :: Coordinate
  }
  |
  PositionEmptyError {
    pos :: Point
  }
  |
  PositionTakenError {
    pos :: Point
  }
  |
  InvalidDimensionError {
    dimension :: Coordinate
  }
  |
  InvalidTrayCapacityError {
      trayCapacity :: Int
  }
  |
  MissingPieceError {
      pos :: Point
  }
  |
  PieceIdNotFoundError {
      id :: String
  }
  |
  PieceValueNotFoundError {
      value :: Char
  }
  |
  MissingPlayerError {
      playerName :: String
  }
  |
  InvalidPlayerNameError {
      playerName :: String
  }
  |
  MissingGameError {
      gameId :: String
  }
  |
  GameTimeoutError {
      gameId :: String
  }
  |
  InvalidWordError {
      word :: String
  }
  |
  NonContiguousPlayError {
      points :: [Point]
  }
  |
  PlayPieceIndexOutOfBoundsError {
      gridPiece :: GridPiece
  }
  |
  MissingBoardPlayPieceError {
      gridPiece :: GridPiece
  }
  |
  UnmatchedBoardPlayPieceError {
      gridPiece :: GridPiece
  }
  |
  OccupiedMoveDestinationError {
      point :: Point
  }
  |
  CrossLinkedMoveDestinationError {
      gridPiece :: GridPiece,
      crossLinkedGridPiece :: GridPiece
  }
  |
  MissingMoveSourceError {
      trayPiece :: Piece
  }
  |
  SystemOverloadedError
  |
  GameTimedOutError {
      gameId :: String
    , timeLimit :: Int
  }
  |
  InternalError {
      message :: String
  }
  deriving (Eq, Show, Generic)

instance FromJSON GameError
instance ToJSON GameError

-- | Return type of low-level IO-dependent function.
type ExceptGame result = ExceptT GameError IO result


-- TODO. May want to pretty-print show for errors.




