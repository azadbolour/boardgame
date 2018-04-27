--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}

{-|
The service layer of the game application. This layer is independent of
communication concerns with clients.
-}
module BoardGame.Server.Service.GameService (
    addPlayerService
  , startGameService
  , commitPlayService
  , machinePlayService
  , swapPieceService
  , closeGameService
  , getGamePlayDetailsService
  , timeoutLongRunningGames
  , prepareDb
  , unknownPlayerName
  -- , unknownPlayer
  )
  where

import Data.Ord
import Data.List
import Data.Maybe (fromJust, isNothing)
import Data.Time (getCurrentTime)
import Data.Bool (bool)
import qualified Data.Map as Map

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..), withExceptT)
import Control.Monad.Trans.Except (ExceptT)
import Control.Monad.Reader (MonadReader(..), asks, ask)
import Control.Monad.Trans.Class (lift)

import Bolour.Util.MiscUtil (isAlphaNumString)
import Bolour.Util.Core (EntityId)
import qualified Bolour.Util.MiscUtil as Util
import Bolour.Util.FrequencyDistribution (FrequencyDistribution(..))
import qualified Bolour.Util.FrequencyDistribution as FrequencyDistribution

import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.Axis as Axis

import Bolour.Language.Util.WordUtil (DictWord)
import qualified Bolour.Language.Domain.WordDictionary as Dict
import Bolour.Language.Domain.WordDictionary (WordDictionary)
import qualified Bolour.Language.Domain.DictionaryCache as DictionaryCache

import BoardGame.Common.Domain.PieceProviderType (PieceProviderType(..))
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType
import BoardGame.Server.Domain.Player (Player(Player), PlayerType(..))
import qualified BoardGame.Server.Domain.Player as Player
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GameMiniState (GameMiniState)
import BoardGame.Common.Domain.GameSummary (GameSummary)
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.GameParams (GameParams)
import qualified BoardGame.Common.Domain.GameParams as GameParams (GameParams(..))
import BoardGame.Server.Domain.Game (Game, Game(Game))
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.GameError (GameError(..))
import BoardGame.Server.Domain.Tray (Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
import BoardGame.Server.Domain.PlayInfo (PlayInfo, PlayInfo(PlayInfo))
import BoardGame.Server.Domain.GameEnv (GameEnv(..))
import BoardGame.Server.Service.GameTransformerStack (GameTransformerStack, exceptTToStack)
import BoardGame.Server.Service.GameDao (
    GameRow(..)
  , PlayerRow(..)
  , PlayerRowId
  , PlayRow(..)
  )
import qualified BoardGame.Server.Service.GameDao as GameDao
import BoardGame.Server.Domain.PlayDetails (PlayDetails(WordPlayDetails), PlayDetails(SwapPlayDetails))
import qualified BoardGame.Server.Domain.PlayDetails as PlayDetails
import qualified BoardGame.Server.Domain.GameEnv as GameEnv (GameEnv(..))
import BoardGame.Server.Domain.ServerConfig as ServerConfig
import qualified BoardGame.Server.Domain.StripMatcher as Matcher
import qualified BoardGame.Server.Domain.Strip as Strip
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import BoardGame.Server.Domain.PieceProvider (PieceProvider(..), mkDefaultCyclicPieceProvider)
import qualified BoardGame.Server.Service.GameLetterDistribution as GameLetterDistribution

unknownPlayerName = "You"
-- unknownPlayer = Player unknownPlayerName

prepareDb :: GameTransformerStack ()
prepareDb = do
  ServerConfig {dbConfig} <- asks GameEnv.serverConfig
  connectionProvider <- asks GameEnv.connectionProvider
  liftIO $ GameDao.migrateDb connectionProvider
  addPlayerIfNotExistsService $ unknownPlayerName

timeoutLongRunningGames :: GameTransformerStack ()
timeoutLongRunningGames = do
  gameCache <- asks GameEnv.gameCache
  serverConfig <- asks GameEnv.serverConfig
  let ServerConfig {maxGameMinutes} = serverConfig
  gamesMap <- GameCache.cacheGetGamesMap gameCache
  utcNow <- liftIO getCurrentTime
  let games = Map.elems gamesMap
      agedGameIds = let aged = ((maxGameMinutes * 60) <) . Game.gameAgeSeconds utcNow
                    in Game.gameId <$> aged `filter` games
  exceptTToStack $ GameCache.deleteItems agedGameIds gameCache
  -- TODO. End the games in the database with a timed out indication.

-- | Service function to add a player to the system.
addPlayerService :: String -> GameTransformerStack ()
addPlayerService playerName = do
  connectionProvider <- asks GameEnv.connectionProvider
  if not (isAlphaNumString playerName) then
    throwError $ InvalidPlayerNameError playerName
  else do
    playerId <- liftIO Util.mkUuid
    let player = Player playerId playerName
    GameDao.addPlayer connectionProvider (playerToRow player)
    return ()

addPlayerIfNotExistsService :: String -> GameTransformerStack ()
addPlayerIfNotExistsService name = do
  connectionProvider <- asks GameEnv.connectionProvider
  if not (isAlphaNumString name) then
    throwError $ InvalidPlayerNameError name
  else do
    playerId <- liftIO Util.mkUuid
    let player = Player playerId name
    GameDao.addPlayerIfNotExists connectionProvider (playerToRow player)
    return ()

-- TODO. Move to GameError.
type GameIOEither a = IO (Either GameError a)

stringExceptLifter :: ExceptT String IO a -> GameTransformerStack a
stringExceptLifter except =
  let errorMapper = InternalError
      exceptGame = errorMapper `withExceptT` except
  in lift (lift exceptGame)

lookupDictionary :: String -> GameTransformerStack WordDictionary
lookupDictionary languageCode = do
  GameEnv {dictionaryCache} <- ask
  stringExceptLifter $ DictionaryCache.lookup languageCode dictionaryCache

-- | Service function to create and start a new game.
startGameService ::
     GameParams
  -> [GridPiece]
  -> [Piece]
  -> [Piece]
  -> [[Int]]
  -> GameTransformerStack Game

startGameService gameParams initGridPieces initUserPieces initMachinePieces pointValues = do
  params @ GameParams.GameParams {dimension, languageCode, pieceProviderType} <- Game.validateGameParams gameParams
  GameEnv { connectionProvider, gameCache } <- ask
  let playerName = GameParams.playerName params
  playerRowId <- GameDao.findExistingPlayerRowIdByName connectionProvider playerName
  dictionary <- lookupDictionary languageCode
  let pieceProvider = mkPieceProvider pieceProviderType
  game @ Game{ gameId } <- Game.mkInitialGame params pieceProvider initGridPieces initUserPieces initMachinePieces pointValues playerName
  GameDao.addGame connectionProvider $ gameToRow playerRowId game
  exceptTToStack $ GameCache.insert game gameCache
  return game

validateCrossWords :: Board -> WordDictionary -> Strip -> String -> GameTransformerStack ()
validateCrossWords board dictionary strip word = do
  let crosswords = CrossWordFinder.findStripCrossWords board strip word
      invalidCrosswords = filter (not . Dict.isWord dictionary) crosswords
  bool (throwError $ InvalidCrossWordError invalidCrosswords) (return ()) (null invalidCrosswords)

-- | Find points on the board that cannot possibly be played
--   and update board accordingly.
updateDeadPoints :: Board -> WordDictionary -> (Board, [Point])
updateDeadPoints = Matcher.setHopelessBlankPointsAsDeadRecursive

-- | Service function to commit a user play - reflecting it on the
--   game's board, and and refilling the user tray.
--   Return the newly added replenishment pieces to the user tray.
commitPlayService ::
     String
  -> [PlayPiece]
  -> GameTransformerStack (GameMiniState, [Piece], [Point])

commitPlayService gmId playPieces = do
  GameEnv { gameCache } <- ask
  game @ Game {languageCode, board} <- exceptTToStack $ GameCache.lookup gmId gameCache
  let playWord = PlayPiece.playPiecesToWord playPieces
  dictionary <- lookupDictionary languageCode
  let wordExists = Dict.isWord dictionary playWord
  -- TODO. Library function for if problem throw error?
  bool (throwError $ InvalidWordError playWord) (return ()) wordExists
  let maybeStrip = Board.stripOfPlay board playPieces
  strip <- case maybeStrip of
           Nothing -> throwError $ WordTooShortError playWord
           Just str -> return str
  validateCrossWords board dictionary strip playWord
  (game' @ Game {board = newBoard, trays, playNumber}, refills)
    <- Game.reflectPlayOnGame game UserPlayer playPieces

  let (newBoard', deadPoints) = updateDeadPoints newBoard dictionary
      game'' = Game.setBoard game' newBoard'

  saveWordPlay gmId playNumber UserPlayer playPieces refills
  exceptTToStack $ GameCache.insert game'' gameCache
  let miniState = Game.toMiniState game''
  return (miniState, refills, deadPoints)

-- TODO. Save the replacement pieces in the database.
-- TODO. Need to save the update game info in the DB.

-- | Service function to obtain the next machine play.
--   If no match is found, then the machine exchanges a piece.
machinePlayService :: String -> GameTransformerStack (GameMiniState, [PlayPiece], [Point])
machinePlayService gameId = do
  GameEnv { gameCache } <- ask
  (game @ Game {gameId, languageCode, board, trays}) <- exceptTToStack $ GameCache.lookup gameId gameCache
  dictionary <- lookupDictionary languageCode
  let machineTray @ Tray {pieces} = trays !! Player.machineIndex
      trayChars = Piece.value <$> pieces
      maybeMatch = Matcher.findOptimalMatch dictionary board trayChars
  (game', machinePlayPieces, deadPoints) <- case maybeMatch of
    Nothing -> do
      gm <- exchangeMachinePiece game
      return (gm, [], []) -- If no pieces were used - we know it was a swap.
    Just (strip, word) -> do
      (playPieces, depletedTray) <- stripMatchAsPlay board machineTray strip word
      (gm @ Game {board = newBoard, trays, playNumber}, refills) <- Game.reflectPlayOnGame game MachinePlayer playPieces

      let (newBoard', deadPoints) = updateDeadPoints newBoard dictionary
          gm' = Game.setBoard gm newBoard'

      saveWordPlay gameId playNumber MachinePlayer playPieces refills
      return (gm', playPieces, deadPoints)

  exceptTToStack $ GameCache.insert game' gameCache
  let miniState = Game.toMiniState game'
  return (miniState, machinePlayPieces, deadPoints)

-- TODO. Save the new game data in the database.
-- TODO. Would this be simpler with a stack of ExceptT May IO??
-- | Service function to swap a user piece for another.
swapPieceService :: String -> Piece -> GameTransformerStack (GameMiniState, Piece)

swapPieceService gameId (piece @ (Piece {id})) = do
  gameCache <- asks GameEnv.gameCache
  (game @ Game {gameId, board, trays}) <- exceptTToStack $ GameCache.lookup gameId gameCache
  let (userTray @ (Tray {pieces})) = trays !! Player.userIndex
  index <- Tray.findPieceIndexById userTray id
  let swappedPiece = pieces !! index
  (game' @ Game {playNumber}, newPiece) <- Game.doExchange game UserPlayer index
  saveSwap gameId playNumber UserPlayer swappedPiece newPiece
  exceptTToStack $ GameCache.insert game' gameCache
  let miniState = Game.toMiniState game'
  return (miniState, newPiece)

-- | No matches available for machine - do a swap instead.
exchangeMachinePiece :: Game -> GameTransformerStack Game
exchangeMachinePiece (game @ Game.Game {gameId, board, trays, playNumber}) = do
  let (machineTray @ (Tray {pieces})) = trays !! Player.machineIndex
  if Tray.isEmpty machineTray
    then return game
    else do
      let piece @ Piece { id } = head pieces
      index <- Tray.findPieceIndexById machineTray id
      (game' @ Game {playNumber}, newPiece) <- Game.doExchange game MachinePlayer index
      -- TODO. Update play number at the right place before using it here.
      saveSwap gameId playNumber MachinePlayer piece newPiece
      return game'

closeGameService :: String -> GameTransformerStack GameSummary
closeGameService gameId = do
  gameCache <- asks GameEnv.gameCache
  game <- exceptTToStack $ GameCache.lookup gameId gameCache
  exceptTToStack $ GameCache.delete gameId gameCache
  return $ Game.summary game
  -- TODO. Tell the database that the game has ended - as opposed to suspended.
  -- TODO. Game.summary should return the game updated with the bonus/penalty scores.
  -- TODO. Persist that final state of the game.


-- TODO. A swap is also a play and should increment the playNumber. For both machine and user.
-- TODO. play number needs to be updated at the right time.

saveWordPlay :: String -> Int -> PlayerType -> [PlayPiece] -> [Piece]
  -> GameTransformerStack EntityId
saveWordPlay gameId playNumber playerType playPieces replacementPieces =
  let playDetails = WordPlayDetails playPieces replacementPieces
      detailsJson = PlayDetails.encode playDetails
  in savePlay gameId playNumber playerType True detailsJson

saveSwap :: String -> Int -> PlayerType -> Piece -> Piece
  -> GameTransformerStack EntityId
saveSwap gameId playNumber playerType swappedPiece replacementPiece =
  let swapDetails = SwapPlayDetails swappedPiece replacementPiece
      detailsJson = PlayDetails.encode swapDetails
  in savePlay gameId playNumber playerType False detailsJson

savePlay ::
     String
  -> Int
  -> PlayerType
  -> Bool
  -> String
  -> GameTransformerStack EntityId
savePlay gameId playNumber playerType isPlay details = do
  connectionProvider <- asks GameEnv.connectionProvider
  gameRowId <- GameDao.findExistingGameRowIdByGameId connectionProvider gameId
  let playRow = PlayRow gameRowId playNumber (show playerType) isPlay details
  GameDao.addPlay connectionProvider playRow

gameToRow :: PlayerRowId -> Game -> GameRow
gameToRow playerId game =
  GameRow gameId playerId (Board.dimension board) trayCapacity
    where gameId = Game.gameId game
          languageCode = Game.languageCode game -- TODO. Add language code to the table.
          board = Game.board game
          trays = Game.trays game
          playerName = Game.playerName game -- TODO. Ditto.
          userTray = trays !! Player.userIndex
          trayCapacity = length $ Tray.pieces (trays !! Player.userIndex) -- TODO. Just use tray capacity.

playerToRow :: Player.Player -> PlayerRow
playerToRow player = PlayerRow $ Player.name player -- TODO. Clean this up.

getGamePlayDetailsService :: String -> GameTransformerStack [PlayInfo]
getGamePlayDetailsService gameId = do
  connectionProvider <- asks GameEnv.connectionProvider
  playRows <- GameDao.getGamePlays connectionProvider gameId
  return $ playRowToPlayInfo <$> playRows

-- TODO. Check for decode returning Nothing - error in decoding.

playRowToPlayInfo :: PlayRow -> PlayInfo
playRowToPlayInfo PlayRow {playRowNumber, playRowTurn, playRowIsPlay, playRowDetails} =
  let maybePlayDetails = PlayDetails.decode playRowDetails
  in PlayInfo playRowNumber (read playRowTurn) (fromJust maybePlayDetails)

stripPoint :: Strip -> Int -> Point
stripPoint (strip @ Strip {axis, lineNumber, begin}) offset =
  case axis of
    Axis.X -> Point lineNumber (begin + offset)
    Axis.Y -> Point (begin + offset) lineNumber

-- | Effect of a strip match in terms of play pieces.
stripMatchAsPlay :: (MonadError GameError m, MonadIO m) => Board -> Tray -> Strip -> DictWord -> m ([PlayPiece], Tray)

stripMatchAsPlay board tray strip word = do
  let playPiecePeeler [] position (playPieces, tray) = return (playPieces, tray)
      playPiecePeeler (wordHead : wordTail) position (playPieces, tray) = do
        let point = stripPoint strip position
            maybePiece = Board.getPiece board point
            moved = isNothing maybePiece
        (piece', tray') <- if not moved then return (fromJust maybePiece, tray)
                           else Tray.removePieceByValue tray wordHead
        let playPiece = PlayPiece piece' point moved
        playPiecePeeler wordTail (position + 1) (playPiece : playPieces, tray')
  (reversePlayPieces, depletedTray) <- playPiecePeeler word 0 ([], tray)
  return (reverse reversePlayPieces, depletedTray)

letterDistribution :: FrequencyDistribution Char
letterDistribution = GameLetterDistribution.letterDistribution

mkPieceProvider :: PieceProviderType -> PieceProvider
mkPieceProvider PieceProviderType.Random =
  let randomizer = FrequencyDistribution.randomValue letterDistribution
  in RandomPieceProvider 0 randomizer

mkPieceProvider PieceProviderType.Cyclic = mkDefaultCyclicPieceProvider
