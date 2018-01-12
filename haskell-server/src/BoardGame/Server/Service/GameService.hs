--
-- Copyright 2017 Azad Bolour
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
  , endGameService
  , getGamePlayDetailsService
  , timeoutLongRunningGames
  , prepareDb
  , unknownPlayerName
  , unknownPlayer
  )
  where

import Data.Ord
import Data.List
import Data.Maybe (fromJust)
import Data.Time (getCurrentTime)

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..), withExceptT)
import Control.Monad.Reader (MonadReader(..), asks, ask)
import Control.Monad.Trans.Except (ExceptT(ExceptT))
import Control.Monad.Trans.Class (lift)

import Bolour.Util.MiscUtil (
  isAlphaNumString,
 )

import BoardGame.Common.Domain.Player (Player(Player), PlayerType(..))
import qualified BoardGame.Common.Domain.Player as Player
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import Bolour.Grid.Point (Point, Point(Point))
-- import qualified Bolour.Grid.Point as Point
-- import Bolour.Grid.Point (Axis)
import qualified Bolour.Grid.Point as Axis
import BoardGame.Common.Domain.GameMiniState (GameMiniState)
import BoardGame.Common.Domain.GameSummary (GameSummary)
import BoardGame.Common.Domain.GridPiece (GridPiece)
-- import Bolour.Grid.GridValue (GridValue, GridValue(GridValue))
-- import qualified Bolour.Grid.GridValue as GridValue
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.GameParams (GameParams)
import qualified BoardGame.Common.Domain.GameParams as GameParams (GameParams(..))
import BoardGame.Server.Domain.Core (EntityId)
import BoardGame.Server.Domain.Game (Game, Game(Game))
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.GameError (GameError(..))
import BoardGame.Server.Domain.Play (Play)
import qualified BoardGame.Server.Domain.Play as Play
import BoardGame.Server.Domain.Tray (Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified BoardGame.Server.Domain.DictionaryCache as DictionaryCache
import qualified BoardGame.Server.Domain.WordDictionary as Dict
import BoardGame.Server.Domain.WordDictionary (WordDictionary)
import BoardGame.Server.Domain.PlayInfo (PlayInfo, PlayInfo(PlayInfo))
import BoardGame.Server.Domain.GameEnv (GameEnv(..))
import BoardGame.Server.Service.GameTransformerStack (GameTransformerStack, liftGameExceptToStack)
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
import qualified BoardGame.Server.Domain.ServerConfig as ServerParameters
import qualified BoardGame.Server.Domain.StripMatcher as Matcher
import qualified BoardGame.Server.Domain.Strip as Strip
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import BoardGame.Util.WordUtil (DictWord)
-- import qualified Bolour.Util.DbConfig as DbConfig

unknownPlayerName = "You"
unknownPlayer = Player unknownPlayerName

prepareDb :: GameTransformerStack ()
prepareDb = do
  ServerConfig {dbConfig} <- asks GameEnv.serverConfig
  connectionProvider <- asks GameEnv.connectionProvider
  liftIO $ GameDao.migrateDb connectionProvider
  -- use this when you get in-memory sqlite working
  -- when (DbConfig.isInMemory dbConfig) $ addPlayerService $ Player unknownPlayerName

timeoutLongRunningGames :: GameTransformerStack ()
timeoutLongRunningGames = do
  gameCache <- asks GameEnv.gameCache
  serverConfig <- asks GameEnv.serverConfig
  let ServerConfig {maxGameMinutes} = serverConfig
  gamesMap <- GameCache.cacheGetGamesMap gameCache
  utcNow <- liftIO getCurrentTime
  -- TODO. Direct function to get map's keys?
  let games = foldl' (++) [] $ (: []) <$> gamesMap
      agedGameIds = let aged = ((maxGameMinutes * 60) <) . Game.gameAgeSeconds utcNow
                     in Game.gameId <$> aged `filter` games
  liftGameExceptToStack $ GameCache.deleteItems agedGameIds gameCache
  -- TODO. End the games in the database with a timed out indication.

-- | Service function to add a player to the system.
addPlayerService :: Player.Player -> GameTransformerStack ()
addPlayerService player = do
  connectionProvider <- asks GameEnv.connectionProvider
  let Player { name } = player
  if not (isAlphaNumString name) then
    throwError $ InvalidPlayerNameError name
  else do
    GameDao.addPlayer connectionProvider (playerToRow player)
    return ()

-- TODO. Move to GameError.
type GameIOEither a = IO (Either GameError a)

-- gameIOEitherLifter :: GameIOEither a -> GameTransformerStack a
-- gameIOEitherLifter ioEither = liftGameExceptToStack $ ExceptT ioEither

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
  -> GameTransformerStack Game
  -- -> GameTransformerStack (Game, Maybe [PlayPiece])

startGameService gameParams initGridPieces initUserPieces initMachinePieces = do
  params @ GameParams.GameParams {dimension, languageCode, pieceProviderType} <- Game.validateGameParams gameParams
  GameEnv { connectionProvider, gameCache } <- ask
  let playerName = GameParams.playerName params
  playerRowId <- GameDao.findExistingPlayerRowIdByName connectionProvider playerName
  dictionary <- lookupDictionary languageCode
  -- let tileSack = RandomPieceGenerator.mkRandomPieceGenerator
  let tileSack = PieceProvider.mkDefaultPieceGen pieceProviderType dimension
  game @ Game{ gameId } <- Game.mkInitialGame params tileSack initGridPieces initUserPieces initMachinePieces playerName
  GameDao.addGame connectionProvider $ gameToRow playerRowId game
  liftGameExceptToStack $ GameCache.insert game gameCache
  -- playPieces <- machinePlayService gameId
  -- Machine play has changed the game. Get the latest.
  -- game' <- liftGameExceptToStack $ GameCache.lookup gameId gameCache
  -- return (game', Just playPieces) -- TODO. Return Nothing playPieces if user goes first.
  return game

-- | Service function to commit a user play - reflecting it on the
--   game's board, and and refilling the user tray.
--   Return the newly added replenishment pieces to the user tray.
commitPlayService ::
     String
  -> [PlayPiece]
  -> GameTransformerStack (GameMiniState, [Piece])

commitPlayService gmId playPieces = do
  GameEnv { gameCache } <- ask
  game @ Game {languageCode} <- liftGameExceptToStack $ GameCache.lookup gmId gameCache
  let playWord = PlayPiece.playPiecesToWord playPieces
  dictionary <- lookupDictionary languageCode
  Dict.validateWord dictionary playWord
  (game' @ Game {playNumber}, refills)
    <- Game.reflectPlayOnGame game UserPlayer playPieces
  saveWordPlay gmId playNumber UserPlayer playPieces refills
  liftGameExceptToStack $ GameCache.insert game' gameCache
  -- let score = length playPieces -- TODO. Get real score.
  let miniState = Game.toMiniState game'
  return $ (miniState, refills)

-- TODO. Save the replacement pieces in the database.
-- TODO. Need to save the update game info in the DB.

-- | Service function to obtain the next machine play.
--   If no match is found, then the machine exchanges a piece.
machinePlayService :: String -> GameTransformerStack (GameMiniState, [PlayPiece])
machinePlayService gameId = do
  GameEnv { gameCache } <- ask
  (game @ Game {gameId, languageCode, board, trays}) <- liftGameExceptToStack $ GameCache.lookup gameId gameCache
  dictionary <- lookupDictionary languageCode
  let machineTray @ Tray {pieces} = trays !! Player.machineIndex
      trayChars = Piece.value <$> pieces
      -- gridRows = Board.charRows board
      maybeMatch = Matcher.findOptimalMatch dictionary board trayChars
      -- yields Maybe (Strip, DictWord)
  liftIO $ print "machine tray"
  liftIO $ print $ show machineTray
  (game', machinePlayPieces) <- case maybeMatch of
    Nothing -> do
      liftIO $ print "no machine play match"
      gm <- exchangeMachinePiece game
      return (gm, []) -- If no pieces were used - we know it was a swap.
    Just (strip, word) -> do
      liftIO $ print "machine play match"
      liftIO $ print $ show word
      (playPieces, depletedTray) <- stripMatchAsPlay board machineTray strip word
      liftIO $ print "playPieces"
      liftIO $ print $ show playPieces
      (gm @ Game {playNumber}, refills) <- Game.reflectPlayOnGame game MachinePlayer playPieces
      saveWordPlay gameId playNumber MachinePlayer playPieces refills
      return (gm, playPieces)
  liftGameExceptToStack $ GameCache.insert game' gameCache
  -- let score = length machinePlayPieces
  let miniState = Game.toMiniState game'
  return (miniState, machinePlayPieces)

-- TODO. Save the new game data in the database.
-- TODO. Would this be simpler with a stack of ExceptT May IO??
-- | Service function to swap a user piece for another.
swapPieceService :: String -> Piece -> GameTransformerStack (GameMiniState, Piece)

swapPieceService gameId (piece @ (Piece {id})) = do
  gameCache <- asks GameEnv.gameCache
  (game @ Game {gameId, board, trays}) <- liftGameExceptToStack $ GameCache.lookup gameId gameCache
  let (userTray @ (Tray {pieces})) = trays !! Player.userIndex
  index <- Tray.findPieceIndexById userTray id
  let swappedPiece = pieces !! index
  (game' @ Game {playNumber}, newPiece) <- Game.doExchange game UserPlayer index
  saveSwap gameId playNumber UserPlayer swappedPiece newPiece
  liftGameExceptToStack $ GameCache.insert game' gameCache
  let miniState = Game.toMiniState game'
  return (miniState, newPiece)

-- | No matches available for machine - do a swap instead.
exchangeMachinePiece :: Game -> GameTransformerStack Game
exchangeMachinePiece (game @ Game.Game {gameId, board, trays, playNumber}) = do
  let (machineTray @ (Tray {pieces})) = trays !! Player.machineIndex
  if Tray.isEmpty machineTray
    then return game
    else do
      let piece @ Piece { id } = head $ pieces
      index <- Tray.findPieceIndexById machineTray id
      (game' @ Game {playNumber}, newPiece) <- Game.doExchange game MachinePlayer index
      -- TODO. Update play number at the right place before using it here.
      saveSwap gameId playNumber MachinePlayer piece newPiece
      return game'

endGameService :: String -> GameTransformerStack GameSummary
endGameService gameId = do
  gameCache <- asks GameEnv.gameCache
  game <- liftGameExceptToStack $ GameCache.lookup gameId gameCache
  liftGameExceptToStack $ GameCache.delete gameId gameCache
  return $ Game.summary game
  -- TODO. Tell the database that the game has ended - as opposed to suspended.
  -- TODO. Game.summary should return the game updated with the bonus/penalty scores.
  -- TODO. Persist that final state of the game.


-- TODO. A swap is also a play and should increment the playNumber. For both machine and user.
-- TODO. play number needs to be updated at the right time.

-- exchangeMachinePiece (game @ Game.Game {gameId, board, trays, playNumber, ..}) = do
--   piece <- liftIO Piece.mkRandomPiece -- TODO. Must get the piece from the game.
--   let (machineTray @ Tray {pieces}) = trays !! Player.machineIndex
--       (Just (_, index)) = Piece.leastFrequentLetter $ Piece.value <$> pieces
--       swappedPiece = pieces !! index
--       tray' = Tray.replacePiece machineTray index piece
--   -- TODO. Update play number at the right place before using it here.
--   saveSwap gameId playNumber MachinePlayer swappedPiece piece
--   return $ Game.setPlayerTray game MachinePlayer tray'

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

-- TODO. More intelligent optimal match based on values of moved pieces.
optimalMatch :: [Play] -> Maybe Play
optimalMatch matches =
  if null matches
    then Nothing
    else Just $ maximumBy (comparing (length . Play.playPieces)) matches

gameToRow :: PlayerRowId -> Game -> GameRow
gameToRow playerId game =
  GameRow gameId playerId (Board.dimension board) trayCapacity
    where gameId = Game.gameId game
          languageCode = Game.languageCode game -- TODO. Add language code to the table.
          board = Game.board game
          trays = Game.trays game
          playerName = Game.playerName game -- TODO. Ditto.
          userTray = trays !! Player.userIndex
          -- Game {gameId, board , trays, playerName} = game -- no can do with existentially-quantified data
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
            piece = fromJust $ Board.get board point
            moved = Piece.isEmpty piece
        (piece', tray') <- if not moved then return (piece, tray)
                           else Tray.removePieceByValue tray wordHead
        let playPiece = PlayPiece piece' point moved
        playPiecePeeler wordTail (position + 1) (playPiece : playPieces, tray')
  (reversePlayPieces, depletedTray) <- playPiecePeeler word 0 ([], tray)
  return (reverse reversePlayPieces, depletedTray)






