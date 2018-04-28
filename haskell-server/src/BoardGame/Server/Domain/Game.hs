--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.Game (
    Game(..)
  , mkInitialGame
  , setPlayerTray
  , validatePlayAgainstGame
  , reflectPlayOnGame
  , doExchange
  , validateGameParams
  , gameAgeSeconds
  , toMiniState
  , summary
  , setBoard
  , getBase
  , fromTransitions
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
import qualified Bolour.Plane.Domain.Point as Point
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Server.Domain.Player (PlayerType(..))
import qualified BoardGame.Server.Domain.Player as PlayerType
import qualified BoardGame.Server.Domain.Player as Player
import Bolour.Plane.Domain.GridValue (GridValue(GridValue))
import BoardGame.Common.Domain.GridPiece (GridPiece)
import qualified Bolour.Plane.Domain.GridValue as GridValue
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.GameMiniState (GameMiniState, GameMiniState(GameMiniState))
import BoardGame.Common.Domain.GameSummary (GameSummary, GameSummary(GameSummary))
import BoardGame.Common.Domain.StopInfo (StopInfo, StopInfo(StopInfo))

import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import BoardGame.Server.Domain.GameError
import BoardGame.Server.Domain.PieceProvider
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import qualified BoardGame.Server.Domain.Scorer as Scorer
import BoardGame.Server.Domain.GameBase (GameBase, GameBase(GameBase))
import qualified BoardGame.Server.Domain.GameBase as GameBase
import BoardGame.Server.Domain.GameTransitions (GameTransitions, GameTransitions(GameTransitions))
import qualified BoardGame.Server.Domain.GameTransitions as GameTransitions

-- TODO. Separate out Game from GameState. See Scala version.

data Game = Game {
    gameId :: String
  , languageCode :: String
  , pointValues :: [[Int]]
  , board :: Board
  , trays :: [Tray.Tray] -- ^ Indexed by Player.playerTypeIndex UserPlayer or MachinePlayer. User 0, Machine 1.
  , playerName :: String
  , playNumber :: Int
  , playTurn :: PlayerType
  , pieceProvider :: PieceProvider
  , scorePlay :: [PlayPiece] -> Int
  , lastPlayScore :: Int
  , numSuccessivePasses :: Int
  , scores :: [Int]
  , startTime :: UTCTime
}

getBase :: Game -> GameBase
getBase Game {gameId, board, trays, languageCode, pieceProvider, pointValues, startTime} =
  GameBase
    gameId
    (Board.dimension board)
    (Tray.capacity $ head trays)
    languageCode
    (PieceProvider.pieceProviderType pieceProvider)
    pointValues
    "" -- playerId -- TODO.
    startTime
    Nothing -- TODO. Add end time.
    [] -- piecePoints :: [GridPiece] -- TODO.
    [] -- initUserPieces :: [Piece], -- TODO.
    [] -- initMachinePieces :: [Piece] - TODO.

fromTransitions :: GameTransitions -> Game
fromTransitions GameTransitions {base, plays} = -- TODO. Implement fromTransitions.
  let GameBase {id, dimension, trayCapacity, languageCode, pieceProviderType, pointValues, startTime, endTime} = base
      emptyTray = Tray trayCapacity []
      emptyTrays = [emptyTray, emptyTray]
      pieceProvider = mkDefaultCyclicPieceProvider -- TODO. Must be based on piece provide type. Dummy for now.
      scorePlay = Scorer.scorePlay $ Scorer.mkScorer pointValues
  in
    Game
      id
      languageCode
      pointValues
      (Board.mkEmptyBoard dimension)
      emptyTrays
      "" -- playerName -- TODO.
      0
      Player.UserPlayer
      pieceProvider
      scorePlay
      initScore
      0
      [0, 0]
      startTime

-- TODO. Add deriving for basic classes.
-- Will need custom instances for pieceProvider - since cyclic piece provider is an infinite structure.

-- TODO. Complete show of game if needed.
instance Show Game where
  show game @ Game {board} = "Game {" ++ "board" ++ show board ++ "}"

maxDimension = 120
maxTraySize = 26
maxSuccessivePasses = 10

passesMaxedOut :: Game -> Bool
passesMaxedOut Game { numSuccessivePasses } = numSuccessivePasses == maxSuccessivePasses

setBoard :: Game -> Board -> Game
setBoard game b = game {board = b}

stopInfo :: Game -> StopInfo
stopInfo game @ Game { board, numSuccessivePasses } =
  StopInfo numSuccessivePasses (Board.isFilled board)

initTray :: (MonadError GameError m, MonadIO m) => Game -> PlayerType -> [Piece] -> m Game
initTray (game @ Game { trays }) playerType initPieces = do
  let Tray.Tray { capacity } = trays !! Player.playerTypeIndex playerType
  let needed = capacity - length initPieces
  (game', newPieces) <- mkPieces needed game
  let tray = Tray capacity (initPieces ++ newPieces)
      game'' = setPlayerTray game' playerType tray
  return game''

updatePieceGenerator :: Game -> PieceProvider -> Game

-- | Explicit record update for fieldGenerator.
--   Cannot do normal update: game {pieceProvider = nextGen} gets compiler error:
--   Record update for insufficiently polymorphic field: pieceProvider.
updatePieceGenerator game generator = game { pieceProvider = generator }

mkPieces :: (MonadError GameError m, MonadIO m) => Int -> Game -> m (Game, [Piece])
mkPieces num (game @ Game { pieceProvider }) = do
  (pieces, leftTileSack) <- PieceProvider.takePieces pieceProvider num
  let game' = game { pieceProvider = leftTileSack }
  return (game', pieces)

-- mkPieces num game = mkPieces' num (game, [])

initScore = 0
initScores = [initScore, initScore]

-- | Note. Validation of player name does not happen here.
mkInitialGame :: (MonadError GameError m, MonadIO m) =>
  GameParams
  -> PieceProvider
  -> [GridPiece]
  -> [Piece]
  -> [Piece]
  -> [[Int]]
  -> String
  -> m Game

-- TODO. Fix duplicated player name.
mkInitialGame gameParams pieceProvider initGridPieces initUserPieces initMachinePieces pointValues playerName = do
  let GameParams.GameParams { dimension, trayCapacity, languageCode } = gameParams
  gameId <- Util.mkUuid
  let board' = Board.mkBoardFromPiecePoints initGridPieces dimension
  now <- liftIO getCurrentTime
  let emptyTray = Tray trayCapacity []
      emptyTrays = [emptyTray, emptyTray]
      scorePlay = Scorer.scorePlay $ Scorer.mkScorer pointValues
      game = Game
                gameId
                languageCode
                pointValues
                board'
                emptyTrays
                playerName
                0
                Player.UserPlayer
                pieceProvider
                scorePlay
                initScore
                0
                initScores
                now
  game' <- initTray game Player.UserPlayer initUserPieces
  initTray game' Player.MachinePlayer initMachinePieces

toMiniState :: Game -> GameMiniState
toMiniState game @ Game {board, pieceProvider, lastPlayScore, scores} =
  let
      gameEnded = passesMaxedOut game || Board.isFilled board
  in GameMiniState lastPlayScore scores gameEnded

gameAgeSeconds :: UTCTime -> Game -> Int
gameAgeSeconds utcNow game =
  let diffTime = diffUTCTime utcNow (startTime game)
      ageSeconds = toInteger $ floor diffTime
  in fromIntegral ageSeconds

summary :: Game -> GameSummary
summary game @ Game {trays, scores} =
  let stopData = stopInfo game
  in GameSummary stopData

setPlayerTray :: Game -> PlayerType -> Tray -> Game
setPlayerTray (game @ Game {trays}) playerType tray =
  let whichTray = Player.playerTypeIndex playerType
      trays' = Util.setListElement trays whichTray tray
  in game {trays = trays'}

-- TODO. The following are only needed for player play.
-- Machine play already satisfies them.
-- TODO. The following are basic sanity checks. Not exhaustive yet. And some may be stubbed. Fix.
-- | Make sure the incoming play is consistent with the state of the game.
validatePlayAgainstGame :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
validatePlayAgainstGame game playPieces =
      checkContiguousPlay playPieces
  >>= checkPlayLineInBounds game
  >>= checkMoveDestinationsEmpty game
  >>= checkMoveTrayPieces game
  >>= checkPlayPositionsOccupied game
  >>= checkPlayBoardPieces game

-- TODO. Check connectivity. Either has to have an anchor or be a parallel play.
-- That is check in teh UI for now. So OK to defer.
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
  Board.validatePoint board (PlayPiece.point (head playPieces))
  Board.validatePoint board (PlayPiece.point (last playPieces))
  return playPieces

-- Assume grid points have been checked to be in bounds.
checkMoveDestinationsEmpty :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkMoveDestinationsEmpty Game {board} playPieces =
  let gridPoints = PlayPiece.point <$> filter PlayPiece.moved playPieces
      maybeTaken = find (Board.pointIsNonEmpty board) gridPoints
  in case maybeTaken of
     Nothing -> return playPieces
     Just taken -> throwError $ OccupiedMoveDestinationError taken

-- TODO. Check cross words. Rename.
-- checkMoveDestinationsFreeCrossWise :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
-- checkMoveDestinationsFreeCrossWise game = return

-- TODO. Implement validation.
checkMoveTrayPieces :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkMoveTrayPieces game = return

-- | Check that the existing board pieces in the purported play are
--   in fact occupied already.
checkPlayPositionsOccupied :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkPlayPositionsOccupied Game {board} playPieces =
  let boardPlayPieces = filter (not . PlayPiece.moved) playPieces
      maybeFreePlayPiece = find (not . Board.pointHasValue board . PlayPiece.point) boardPlayPieces
  in case maybeFreePlayPiece of
     Nothing -> return playPieces
     Just missingPlayPiece -> throwError $ MissingBoardPlayPieceError $ PlayPiece.getGridPiece missingPlayPiece

-- | Check that purported play pieces already on the board indicated on a play
--   do exist on the board.
checkPlayBoardPieces :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkPlayBoardPieces Game {board} playPieces =
  let boardPlayPieces = filter (not . PlayPiece.moved) playPieces
      gridPieces = PlayPiece.getGridPiece <$> boardPlayPieces
      gridPieceMatchesBoard GridValue {value = piece, point} =
        let maybePiece = Board.getPiece board point
        in case maybePiece of
           Nothing -> False
           Just boardPiece -> boardPiece == piece
      maybeMismatch = find (not . gridPieceMatchesBoard) gridPieces
  in case maybeMismatch of
       Nothing -> return playPieces
       Just gridPiece -> throwError $ UnmatchedBoardPlayPieceError gridPiece

reflectPlayOnGame :: (MonadError GameError m, MonadIO m) => Game -> PlayerType -> [PlayPiece] -> m (Game, [Piece])
reflectPlayOnGame (game @ Game {board, trays, playNumber, numSuccessivePasses, scorePlay, scores}) playerType playPieces = do
  _ <- if playerType == PlayerType.UserPlayer then validatePlayAgainstGame game playPieces else return playPieces
  let movedPlayPieces = filter PlayPiece.moved playPieces
      movedGridPieces = PlayPiece.getGridPiece <$> movedPlayPieces
      b = Board.setPiecePoints board movedGridPieces
      usedPieces = GridValue.value <$> movedGridPieces
      playerIndex = Player.playerTypeIndex playerType
  (game', newPieces) <- mkPieces (length usedPieces) game
  let tray = trays !! playerIndex
      tray' = Tray.replacePieces tray usedPieces newPieces
      trays' = Util.setListElement trays playerIndex tray'
      playNumber' = playNumber + 1
      -- score' = length playPieces -- TODO. Compute real score.
      earlierScore = scores !! playerIndex
      thisScore = scorePlay playPieces
      score' = earlierScore + thisScore
      scores' = Util.setListElement scores playerIndex score'
  return (game' { board = b, trays = trays', playNumber = playNumber', lastPlayScore = thisScore, numSuccessivePasses = 0, scores = scores' }, newPieces)

doExchange :: (MonadError GameError m, MonadIO m) => Game -> PlayerType -> Int -> m (Game, Piece)
doExchange (game @ Game {gameId, board, trays, pieceProvider, numSuccessivePasses}) playerType trayPos = do
  let whichTray = Player.playerTypeIndex playerType
      tray @ Tray {pieces} = trays !! whichTray
      piece = pieces !! trayPos
      succPasses = numSuccessivePasses + 1
      game' = game { numSuccessivePasses = succPasses, lastPlayScore = 0 }
  (piece', pieceProvider1) <- PieceProvider.swapOne pieceProvider piece
  let game'' = game' { pieceProvider = pieceProvider1 }
      tray' = Tray.replacePiece tray trayPos piece'
      game''' = setPlayerTray game'' playerType tray'
  return (game''', piece')

-- Either is a MonadError - but this generalizes the function.
-- In general rather than using a specific monad, use an mtl type class
-- that abstracts the specific functions provided by that monad.
-- Here rather than Either we use MonadError.
validateGameParams :: MonadError GameError m => GameParams -> m GameParams
validateGameParams params =
  let GameParams.GameParams {dimension, trayCapacity, playerName} = params
  in
    if dimension <= 0 || dimension > maxDimension then
      throwError $ InvalidDimensionError dimension
    else if trayCapacity <= 0 || trayCapacity > maxTraySize then
      throwError $ InvalidTrayCapacityError trayCapacity
    else if not (all isAlphaNum playerName) then
      throwError $ InvalidPlayerNameError playerName
    else return params
