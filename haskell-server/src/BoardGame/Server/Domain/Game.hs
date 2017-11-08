--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ExistentialQuantification #-}

module BoardGame.Server.Domain.Game (
    Game(..)
  , mkInitialGame
  , addPlayedPieces
  , setPlayerTray
  , validatePlayAgainstGame
  , reflectPlayOnGame
  , doExchange
  , validateGameParams
  , gameAgeSeconds
)
where

import Data.Char (isAlphaNum)
import Data.List
import Data.Time (UTCTime, getCurrentTime)
import Data.Time.Clock (diffUTCTime)

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..))

import qualified Bolour.Util.MiscUtil as Util

import BoardGame.Common.Domain.GameParams as GameParams -- allows both qualified and unqualified names
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.Player (PlayerType(..))
import qualified BoardGame.Common.Domain.Player as Player
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Common.Domain.GridPiece (GridPiece)
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.PlayPiece (PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece

import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import BoardGame.Server.Domain.GameError
import BoardGame.Server.Domain.PieceGenerator
import qualified BoardGame.Server.Domain.PieceGenerator as PieceGenerator

-- We use existential quantification for the piece generator field of Game
-- which is abstract (whose type is the type class PieceGenerator).
-- This is done in order to avoid being forced to parameterize Game by the type
-- of the piece generator, which is necessary without existential quantification.
-- Without existential quantification, every use of Game in a function anywhere in
-- the code base would have to provide a type parameter to game for the piece generator.
-- This would pollute the code with a type parameter that in most cases is not and
-- should not be of concern to a function using Game as a parameter.

data Game = forall pieceGenerator . PieceGenerator pieceGenerator => Game {
    gameId :: String
  , languageCode :: String
  , board :: Board
  , trays :: [Tray.Tray] -- ^ Indexed by Player.playerTypeIndex UserPlayer or MachinePlayer. User 0, Machine 1.
  , playerName :: Player.PlayerName
  , playNumber :: Int
  , playTurn :: PlayerType
  , pieceGenerator :: pieceGenerator
  , score :: [Int]
  , startTime :: UTCTime
}

-- Can't do deriving on Game because it has existential constraint.

-- TODO. Complete show of game if needed.
instance Show Game where
  show game @ Game {board} = "Game {" ++ "board" ++ show board ++ "}"

maxDimension = 120
maxTraySize = 26

initTray :: (MonadError GameError m, MonadIO m) => Game -> PlayerType -> [Piece] -> m Game
initTray (game @ Game { trays }) playerType initPieces = do
  let Tray.Tray { capacity } = trays !! Player.playerTypeIndex playerType
  let needed = capacity - length initPieces
  (game', newPieces) <- liftIO $ mkPieces needed game
  let tray = Tray capacity (initPieces ++ newPieces)
      game'' = setPlayerTray game' playerType tray
  return game''

updatePieceGenerator :: PieceGenerator pieceGenerator =>
  Game -> pieceGenerator -> Game

-- | Explicit record update for fieldGenerator.
--   Cannot do normal update: game {pieceGenerator = nextGen} gets compiler error:
--   Record update for insufficiently polymorphic field: pieceGenerator.
updatePieceGenerator
  Game {gameId, languageCode, board, trays, playerName, playNumber, playTurn, pieceGenerator, score, startTime} generator =
    Game gameId languageCode board trays playerName playNumber playTurn generator score startTime

mkPiece :: MonadIO m => Game -> m (Game, Piece)
mkPiece (game @ Game {pieceGenerator}) = do
  (piece, nextGen) <- liftIO $ PieceGenerator.next pieceGenerator
  let game' = updatePieceGenerator game nextGen
  -- let game' = game { pieceGenerator = nextGen}
  -- piece <- liftIO $ Piece.mkRandomPieceForId (show id)
  return (game', piece)

mkPieces' :: MonadIO m => Int -> (Game, [Piece]) -> m (Game, [Piece])
mkPieces' 0 (game, pieces) = return (game, pieces)
mkPieces' n (game, pieces) = do
  (game', piece) <- mkPiece game
  mkPieces' (n - 1) (game', piece:pieces)

mkPieces :: MonadIO m => Int -> Game -> m (Game, [Piece])
mkPieces num game = mkPieces' num (game, [])

initScores = [0, 0]

-- | Note. Validation of player name does not happen here.
mkInitialGame :: (PieceGenerator pieceGenerator, MonadError GameError m, MonadIO m) =>
  GameParams
  -> pieceGenerator
  -> [GridPiece]
  -> [Piece]
  -> [Piece]
  -> Player.PlayerName
  -> m Game

-- TODO. Fix duplicated player name.
mkInitialGame gameParams pieceGenerator initGridPieces initUserPieces initMachinePieces playerName = do
  let GameParams.GameParams { height, width, trayCapacity, languageCode } = gameParams
  gameId <- Util.mkUuid
  board <- Board.mkBoard height width
  board' <- primeBoard board initGridPieces
  now <- liftIO getCurrentTime
  let emptyTray = Tray trayCapacity []
      emptyTrays = [emptyTray, emptyTray]
      game = Game gameId languageCode board' emptyTrays playerName 0 Player.UserPlayer pieceGenerator initScores now
  game' <- initTray game Player.UserPlayer initUserPieces
  initTray game' Player.MachinePlayer initMachinePieces

gameAgeSeconds :: UTCTime -> Game -> Int
gameAgeSeconds utcNow game =
  let diffTime = diffUTCTime utcNow (startTime game)
      ageSeconds = toInteger $ floor diffTime
  in fromIntegral ageSeconds

defaultInitialGridPieces :: MonadIO m => Board -> m [GridPiece]
defaultInitialGridPieces board = do
  let point = Board.centerGridPoint board
  piece <- liftIO $ Piece.mkPiece 'E' -- TODO. Use Game.mkPiece.
  return [GridValue piece point]

primeBoard :: MonadIO m => Board -> [GridPiece] -> m Board
primeBoard board inputGridPieces = do
  defaultGridPieces <- defaultInitialGridPieces board
  let addGridPiece bd (GridValue.GridValue {value = piece, point}) = Board.setBoardValue bd point piece
      board' = foldl' addGridPiece board inputGridPieces
  return board'

setPlayerTray :: Game -> PlayerType -> Tray -> Game
setPlayerTray (game @ Game {trays}) playerType tray =
  let whichTray = Player.playerTypeIndex playerType
      trays' = Util.setListElement trays whichTray tray
  in game {trays = trays'}

-- TODO. The following are basic sanity checks. Not exhaustive yet. And some may be stubbed. Fix.
-- | Make sure the incoming play is consistent with the state of the game.
validatePlayAgainstGame :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
validatePlayAgainstGame game playPieces =
      checkContiguousPlay playPieces
  >>= checkPlayLineInBounds game
  >>= checkMoveDestinationsEmpty game
  >>= checkMoveDestinationsFreeCrossWise game
  >>= checkMoveTrayPieces game
  >>= checkPlayPositionsOccupied game
  >>= checkPlayBoardPieces game

checkContiguousPlay :: MonadError GameError m => [PlayPiece] -> m [PlayPiece]
checkContiguousPlay playPieces =
  let points = PlayPiece.point <$> playPieces
      contiguousBy f = Util.contiguous (f <$> points)
  in if contiguousBy Point.row || contiguousBy Point.col then
       return playPieces
     else throwError $ NonContiguousPlayError points

checkPlayLineInBounds :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkPlayLineInBounds _ [] = return []
checkPlayLineInBounds (Game { board }) playPieces = do
  Board.checkGridPoint board (PlayPiece.point (head playPieces))
  Board.checkGridPoint board (PlayPiece.point (last playPieces))
  return playPieces

-- Assume grid points have been checked to be in bounds.
checkMoveDestinationsEmpty :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkMoveDestinationsEmpty Game {board} playPieces =
  let gridPoints = PlayPiece.point <$> filter PlayPiece.moved playPieces
      maybeTaken = find (Board.validPositionIsTaken board) gridPoints
  in case maybeTaken of
     Nothing -> return playPieces
     Just taken -> throwError $ OccupiedMoveDestinationError taken

-- TODO. Implement validation.
checkMoveDestinationsFreeCrossWise :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkMoveDestinationsFreeCrossWise game = return

-- TODO. Implement validation.
checkMoveTrayPieces :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkMoveTrayPieces game = return

-- | Check that the existing board pieces in the purported play are
--   in fact occupied already.
checkPlayPositionsOccupied :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkPlayPositionsOccupied Game {board} playPieces =
  let boardPlayPieces = filter (not . PlayPiece.moved) playPieces
      maybeFreePlayPiece = find (Board.validPositionIsFree board . PlayPiece.point) boardPlayPieces
  in case maybeFreePlayPiece of
     Nothing -> return playPieces
     Just freePlayPiece -> throwError $ MissingBoardPlayPieceError $ PlayPiece.getGridPiece freePlayPiece

-- | Check that purported play pieces already on the board indicated on a play
--   do exist on the board.
checkPlayBoardPieces :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkPlayBoardPieces Game {board} playPieces =
  let boardPlayPieces = filter (not . PlayPiece.moved) playPieces
      gridPieces = PlayPiece.getGridPiece <$> boardPlayPieces
      boardPiece point = GridValue.value $ Board.getValidGridPiece board point
      matchesBoard GridValue {value = piece, point} = Piece.eqValue (boardPiece point) piece
      maybeMismatch = find (not . matchesBoard) gridPieces
  in case maybeMismatch of
       Nothing -> return playPieces
       Just gridPiece -> throwError $ UnmatchedBoardPlayPieceError gridPiece

reflectPlayOnGame :: (MonadError GameError m, MonadIO m) => Game -> PlayerType -> [PlayPiece] -> m (Game, [Piece])
reflectPlayOnGame game playerType playPieces = do
  playPieces' <- validatePlayAgainstGame game playPieces
  let movedPlayPieces = filter PlayPiece.moved playPieces'
      movedGridPieces = PlayPiece.getGridPiece <$> movedPlayPieces
  addPlayedPieces game playerType movedGridPieces

-- | Update the representation of the game by moving the moved
--   pieces of a play from the corresponding tray to the game's board,
--   then replenish the spent pieces of that tray and return the
--   updated game, and the replenished pieces. TODO. Better name for this function.
addPlayedPieces :: MonadIO m => Game -> PlayerType -> [GridPiece] -> m (Game, [Piece])
addPlayedPieces (game @ Game {board, trays, playNumber}) playerType playedGridPieces = do
  let b = Board.setBoardPieces board playedGridPieces
      usedPieces = GridValue.value <$> playedGridPieces
      whichTray = Player.playerTypeIndex playerType
  (game', newPieces) <- mkPieces (length usedPieces) game
  let tray = trays !! whichTray
      tray' = Tray.replacePieces tray usedPieces newPieces
      trays' = Util.setListElement trays whichTray tray'
      playNumber' = playNumber + 1
  return (game' { board = b, trays = trays', playNumber = playNumber'}, newPieces)

doExchange :: (MonadIO m) => Game -> PlayerType -> Int -> m (Game, Piece)
doExchange (game @ Game {gameId, board, trays}) playerType trayPos = do
  (game', piece') <- mkPiece game
  let whichTray = Player.playerTypeIndex playerType
      tray = trays !! whichTray
      tray' = Tray.replacePiece tray trayPos piece'
      game'' = setPlayerTray game' playerType tray'
  return (game'', piece')

-- Either is a MonadError - but this generalizes the function.
-- In general rather than using a specific monad, use an mtl type class
-- that abstracts the specific functions provided by that monad.
-- Here rather than Either we use MonadError.
validateGameParams :: MonadError GameError m => GameParams -> m GameParams
validateGameParams params =
  let GameParams.GameParams {height, width, trayCapacity, playerName} = params
  in
    if height <= 0 || height > maxDimension then
      throwError $ InvalidDimensionError Point.Y height
    else if width <= 0 || width > maxDimension then
      throwError $ InvalidDimensionError Point.X width
    else if trayCapacity <= 0 || trayCapacity > maxTraySize then
      throwError $ InvalidTrayCapacityError trayCapacity
    else if not (all isAlphaNum playerName) then
      throwError $ InvalidPlayerNameError playerName
    else return params
