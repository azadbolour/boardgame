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
-- {-# LANGUAGE ExistentialQuantification #-}

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
import BoardGame.Common.Domain.GameMiniState (GameMiniState, GameMiniState(GameMiniState))
import BoardGame.Common.Domain.GameSummary (GameSummary, GameSummary(GameSummary))
import BoardGame.Common.Domain.StopInfo (StopInfo, StopInfo(StopInfo))

import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import BoardGame.Server.Domain.GameError
import BoardGame.Server.Domain.TileSack
import qualified BoardGame.Server.Domain.TileSack as TileSack
import BoardGame.Server.Domain.Scorer (Scorer)
import qualified BoardGame.Server.Domain.Scorer as Scorer

-- TODO. Separate out Game from GameState. See Scala version.

data Game = Game {
    gameId :: String
  , languageCode :: String
  , board :: Board
  , trays :: [Tray.Tray] -- ^ Indexed by Player.playerTypeIndex UserPlayer or MachinePlayer. User 0, Machine 1.
  , playerName :: Player.PlayerName
  , playNumber :: Int
  , playTurn :: PlayerType
  , tileSack :: TileSack
  , scorePlay :: [PlayPiece] -> Int
  , lastPlayScore :: Int
  , numSuccessivePasses :: Int
  , scores :: [Int]
  , startTime :: UTCTime
}

-- TODO. Add deriving for basic classes.
-- Will need custom instances for tileSack - since cyclic tile sack is an infinite structure.

-- TODO. Complete show of game if needed.
instance Show Game where
  show game @ Game {board} = "Game {" ++ "board" ++ show board ++ "}"

maxDimension = 120
maxTraySize = 26
maxSuccessivePasses = 6

passesMaxedOut :: Game -> Bool
passesMaxedOut Game { numSuccessivePasses } = numSuccessivePasses == maxSuccessivePasses

isSackEmpty :: Game -> Bool
isSackEmpty Game { tileSack } = TileSack.isEmpty tileSack

isUserTrayEmpty :: Game -> Bool
isUserTrayEmpty Game { trays } = Tray.isEmpty $ trays !! Player.userIndex

isMachineTrayEmpty :: Game -> Bool
isMachineTrayEmpty Game { trays } = Tray.isEmpty $ trays !! Player.machineIndex

noMorePlays :: Game -> Bool
noMorePlays game = passesMaxedOut game || (isSackEmpty game && (isUserTrayEmpty game || isMachineTrayEmpty game))

stopInfo :: Game -> StopInfo
stopInfo game @ Game { trays, tileSack, numSuccessivePasses } =
  StopInfo
    numSuccessivePasses
    maxSuccessivePasses
    (isSackEmpty game)
    (isUserTrayEmpty game)
    (isMachineTrayEmpty game)

initTray :: (MonadError GameError m, MonadIO m) => Game -> PlayerType -> [Piece] -> m Game
initTray (game @ Game { trays }) playerType initPieces = do
  let Tray.Tray { capacity } = trays !! Player.playerTypeIndex playerType
  let needed = capacity - length initPieces
  (game', newPieces) <- mkPieces needed game
  let tray = Tray capacity (initPieces ++ newPieces)
      game'' = setPlayerTray game' playerType tray
  return game''

updatePieceGenerator :: Game -> TileSack -> Game

-- | Explicit record update for fieldGenerator.
--   Cannot do normal update: game {tileSack = nextGen} gets compiler error:
--   Record update for insufficiently polymorphic field: tileSack.
updatePieceGenerator game generator = game { tileSack = generator }

mkPieces :: (MonadError GameError m, MonadIO m) => Int -> Game -> m (Game, [Piece])
mkPieces num (game @ Game { tileSack }) = do
  (pieces, leftTileSack) <- TileSack.takeAvailableTiles tileSack num
  let game' = game { tileSack = leftTileSack }
  return (game', pieces)

-- mkPieces num game = mkPieces' num (game, [])

initScore = 0
initScores = [initScore, initScore]

-- | Note. Validation of player name does not happen here.
mkInitialGame :: (MonadError GameError m, MonadIO m) =>
  GameParams
  -> TileSack
  -> [GridPiece]
  -> [Piece]
  -> [Piece]
  -> Player.PlayerName
  -> m Game

-- TODO. Fix duplicated player name.
mkInitialGame gameParams tileSack initGridPieces initUserPieces initMachinePieces playerName = do
  let GameParams.GameParams { dimension, trayCapacity, languageCode } = gameParams
  gameId <- Util.mkUuid
  let board = Board.mkEmptyBoard dimension
  board' <- primeBoard board initGridPieces
  now <- liftIO getCurrentTime
  let emptyTray = Tray trayCapacity []
      emptyTrays = [emptyTray, emptyTray]
      scorePlay = Scorer.scorePlay $ Scorer.mkScorer dimension trayCapacity
      game = Game
                gameId
                languageCode
                board'
                emptyTrays
                playerName
                0
                Player.UserPlayer
                tileSack
                (scorePlay board')
                initScore
                0
                initScores
                now
  game' <- initTray game Player.UserPlayer initUserPieces
  initTray game' Player.MachinePlayer initMachinePieces

toMiniState :: Game -> GameMiniState
toMiniState game @ Game {tileSack, lastPlayScore, scores} =
  let
      tilesLeft = TileSack.length' tileSack
      gameEnded = noMorePlays game
  in GameMiniState lastPlayScore scores tilesLeft gameEnded

gameAgeSeconds :: UTCTime -> Game -> Int
gameAgeSeconds utcNow game =
  let diffTime = diffUTCTime utcNow (startTime game)
      ageSeconds = toInteger $ floor diffTime
  in fromIntegral ageSeconds

summary :: Game -> GameSummary
summary game @ Game {trays, scores} =
  let stopData = stopInfo game
      userSum = Tray.sumLetterWeights $ trays !! Player.userIndex
      machineSum = Tray.sumLetterWeights $ trays !! Player.machineIndex
      bonus thisSum thatSum =
        if thisSum > 0
          then -thisSum
          else thatSum
      userBonus = bonus userSum machineSum
      machineBonus = bonus machineSum userSum
      endScores = [userBonus, machineBonus]
      totalScores = zipWith (+) scores endScores
      -- TODO. Update the game with the final score and return so it can be persisted.
  in GameSummary stopData endScores totalScores

primeBoard :: MonadIO m => Board -> [GridPiece] -> m Board
primeBoard board inputGridPieces = do
  -- defaultGridPieces <- defaultInitialGridPieces board
  let addGridPiece bd (GridValue.GridValue {value = piece, point}) = Board.set bd point piece
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
      maybeFreePlayPiece = find (Board.pointIsEmpty board . PlayPiece.point) boardPlayPieces
  in case maybeFreePlayPiece of
     Nothing -> return playPieces
     Just freePlayPiece -> throwError $ MissingBoardPlayPieceError $ PlayPiece.getGridPiece freePlayPiece

-- | Check that purported play pieces already on the board indicated on a play
--   do exist on the board.
checkPlayBoardPieces :: MonadError GameError m => Game -> [PlayPiece] -> m [PlayPiece]
checkPlayBoardPieces Game {board} playPieces =
  let boardPlayPieces = filter (not . PlayPiece.moved) playPieces
      gridPieces = PlayPiece.getGridPiece <$> boardPlayPieces
      gridPieceMatchesBoard GridValue {value = piece, point} =
        let maybePiece = Board.get board point
        in case maybePiece of
           Nothing -> False
           Just boardPiece -> boardPiece == piece
      maybeMismatch = find (not . gridPieceMatchesBoard) gridPieces
  in case maybeMismatch of
       Nothing -> return playPieces
       Just gridPiece -> throwError $ UnmatchedBoardPlayPieceError gridPiece

reflectPlayOnGame :: (MonadError GameError m, MonadIO m) => Game -> PlayerType -> [PlayPiece] -> m (Game, [Piece])
reflectPlayOnGame (game @ Game {board, trays, playNumber, numSuccessivePasses, scorePlay, scores}) playerType playPieces = do
  playPieces' <- validatePlayAgainstGame game playPieces
  let movedPlayPieces = filter PlayPiece.moved playPieces'
      movedGridPieces = PlayPiece.getGridPiece <$> movedPlayPieces
      b = Board.setN board movedGridPieces
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
doExchange (game @ Game {gameId, board, trays, tileSack, numSuccessivePasses}) playerType trayPos = do
  let whichTray = Player.playerTypeIndex playerType
      tray @ Tray {pieces} = trays !! whichTray
      piece = pieces !! trayPos
      succPasses = numSuccessivePasses + 1
      game' = game { numSuccessivePasses = succPasses }
  if TileSack.isEmpty tileSack
    then return (game', piece)
    else do
      (piece', sack1) <- TileSack.swapOne tileSack piece
      let game'' = game' { tileSack = sack1 }
          tray' = Tray.replacePiece tray trayPos piece'
          game''' = setPlayerTray game' playerType tray'
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
