--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE DeriveGeneric #-}

module BoardGame.Server.Domain.GameError (
    GameError(..)
  , ExceptGame
  , getMessage
  , encodeGameErrorWithMessage
)
where

import qualified Data.Text as Text
import Data.ByteString.Lazy.Char8 as BS

import qualified Data.HashMap.Strict as HashMap

import Data.String.Here.Interpolated (iTrim)
import GHC.Generics
-- import Data.Aeson
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson
import Data.Aeson (encode, decode, toJSON, Value, Value(Object))

import Control.Monad.Except (ExceptT)

import Bolour.Plane.Domain.Axis
import Bolour.Plane.Domain.Point
import BoardGame.Common.Domain.Piece (Piece(..), Piece(Piece))
import BoardGame.Common.Domain.PiecePoint (PiecePoint(..), PiecePoint(PiecePoint))
import qualified BoardGame.Common.Domain.Piece as Piece

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
      pieceId :: String
  }
  |
  PieceValueNotFoundError {
      pieceValue :: Char
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
  PlayerNameExistsError {
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
  WordTooShortError {
      word :: String
  }
  |
  InvalidCrossWordError {
      crossWords :: [String]
  }
  |
  NonContiguousPlayError {
      points :: [Point]
  }
  |
  PlayPieceIndexOutOfBoundsError {
      piecePoint :: PiecePoint
  }
  |
  MissingBoardPlayPieceError {
      piecePoint :: PiecePoint
  }
  |
  UnmatchedBoardPlayPieceError {
      piecePoint :: PiecePoint
  }
  |
  OccupiedMoveDestinationError {
      point :: Point
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

getMessage :: GameError -> String

getMessage PositionOutOfBoundsError {axis, range, position} =
  [iTrim|position ${position} outside valid range ${range}|]
getMessage PositionEmptyError {pos} =
  [iTrim|position ${pos} is empty|]
getMessage PositionTakenError {pos} =
  [iTrim|position ${pos} is taken|]
getMessage InvalidDimensionError {dimension} =
  [iTrim|invalid board dimension ${dimension}|]
getMessage InvalidTrayCapacityError {trayCapacity} =
  [iTrim|invalid trayCapacity ${trayCapacity}|]
getMessage MissingPieceError {pos} =
  [iTrim|expected a piece at position ${pos} but found none|]
getMessage PieceIdNotFoundError {pieceId} =
  [iTrim|piece id ${pieceId} not found|]
getMessage PieceValueNotFoundError {pieceValue} =
  [iTrim|failed to find piece with value '${pieceValue}'|]
getMessage MissingPlayerError {playerName} =
  [iTrim|player name ${playerName} not found|]
getMessage InvalidPlayerNameError {playerName} =
  [iTrim|invalid player name ${playerName}|]
getMessage PlayerNameExistsError {playerName} =
  [iTrim|duplicate player name ${playerName}|]
getMessage MissingGameError {gameId} =
  [iTrim|game id ${gameId} does not exist|]
getMessage GameTimeoutError {gameId} =
  [iTrim|game id ${gameId} was timed out|]
getMessage InvalidWordError {word} =
  [iTrim|'${word}' not found in the dictionary|]
getMessage WordTooShortError {word} =
  [iTrim|word '${word}' not accepted - it is too short|]
getMessage InvalidCrossWordError {crossWords} =
  [iTrim|crosswords '${crossWords}' not found in the dictionary|]
getMessage NonContiguousPlayError {points} =
  [iTrim|word play locations '${points}' are not contiguous|]
getMessage PlayPieceIndexOutOfBoundsError {piecePoint} =
  let PiecePoint {piece, point} = piecePoint
      Piece {value = letter} = piece
  in [iTrim|attempt to play letter '${letter}' off the board at position ${point}|]
getMessage MissingBoardPlayPieceError {piecePoint} =
  let PiecePoint {piece, point} = piecePoint
      Piece {Piece.value = letter} = piece
  in [iTrim|play uses existing '${letter}' for position ${point} which does not exist|]
getMessage UnmatchedBoardPlayPieceError {piecePoint} =
  let PiecePoint {piece, point} = piecePoint
      Piece {Piece.value = letter} = piece
  in [iTrim|board position '${point}' has a different piece than that claimed in the play: '${letter}'|]
getMessage OccupiedMoveDestinationError {point} =
  [iTrim|board position '${point}' used in play is already occupied|]
getMessage SystemOverloadedError =
  [iTrim|the system is currently overloaded|]
getMessage GameTimedOutError {gameId, timeLimit} =
  [iTrim|the system is currently overloaded|]
getMessage InternalError {message} = message

jsonMessageFieldName = Text.pack "message"

encodeGameErrorWithMessage :: GameError -> ByteString
encodeGameErrorWithMessage gameError =
  let message = getMessage gameError
      messageValue = Aeson.String $ Text.pack message
      errorValue = toJSON gameError
      hashMap =
        case errorValue of
          Object map -> map
          _ -> HashMap.empty -- Defensively. Should never happen.
      hashMap' = HashMap.insert jsonMessageFieldName messageValue hashMap
  in encode $ Object hashMap'

