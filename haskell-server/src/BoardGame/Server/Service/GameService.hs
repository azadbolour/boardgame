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
  )
  where

import Data.Ord
import Data.List
import Data.Maybe (fromJust)
import Data.Time (getCurrentTime)
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..), withExceptT)
import Control.Monad.Reader (MonadReader(..), asks, ask)
import Control.Monad.Trans.Except (ExceptT, ExceptT(ExceptT))
import Control.Monad.Trans.Class (lift)

import Bolour.Util.MiscUtil (
  isAlphaNumString,
 )

import BoardGame.Common.Domain.Player (Player(Player), PlayerType(..))
import qualified BoardGame.Common.Domain.Player as Player
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
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
import qualified BoardGame.Server.Domain.BoardStripMatcher as BoardStripMatcher
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified BoardGame.Server.Domain.DictionaryCache as DictionaryCache
-- import qualified BoardGame.Server.Domain.LanguageDictionary as LanguageDictionary
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
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
import qualified BoardGame.Server.Domain.GameConfig as Config
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters

timeoutLongRunningGames :: GameTransformerStack ()
timeoutLongRunningGames = do
  gameCache <- asks GameEnv.gameCache
  config <- asks GameEnv.config
  let Config.Config {serverParameters} = config
      ServerParameters.ServerParameters {maxGameMinutes} = serverParameters
  gamesMap <- GameCache.cacheGetGamesMap gameCache
  utcNow <- liftIO getCurrentTime
  -- TODO. Direct function to get map's keys?
  let games = foldl' (++) [] $ (: []) <$> gamesMap
      agedGameIds = let aged = ((maxGameMinutes * 60) <) . Game.gameAgeSeconds utcNow
                     in Game.gameId <$> aged `filter` games
  GameCache.cacheRemoveGames gameCache agedGameIds gameIOEitherLifter

-- | Service function to add a player to the system.
addPlayerService :: Player.Player -> GameTransformerStack ()
addPlayerService player = do
  let Player { name } = player
  if not (isAlphaNumString name) then
    throwError $ InvalidPlayerNameError name
  else do
    GameDao.addPlayer (playerToRow player)
    return ()

-- TODO. Move to GameError.
type GameIOEither a = IO (Either GameError a)

gameIOEitherLifter :: GameIOEither a -> GameTransformerStack a
gameIOEitherLifter ioEither = liftGameExceptToStack $ ExceptT ioEither

stringExceptLifter :: ExceptT String IO a -> GameTransformerStack a
stringExceptLifter except =
  let errorMapper = InternalError
      exceptGame = errorMapper `withExceptT` except
  in lift (lift exceptGame)

-- | Service function to create and start a new game.
startGameService ::
     GameParams
  -> [GridPiece]
  -> [Piece]
  -> [Piece]
  -> GameTransformerStack Game

startGameService gameParams gridPieces initUserPieces initMachinePieces = do
  params @ GameParams.GameParams {languageCode} <- Game.validateGameParams gameParams
  GameEnv { config, gameCache, dictionaryCache } <- ask
  let ServerParameters.ServerParameters {dictionaryDir} = Config.serverParameters config
  let playerName = GameParams.playerName params
  playerRowId <- GameDao.findExistingPlayerRowIdByName playerName
  dictionary <- stringExceptLifter $ DictionaryCache.getDictionary dictionaryCache languageCode
  game <- Game.mkInitialGame params gridPieces initUserPieces initMachinePieces playerName
  GameDao.addGame $ gameToRow playerRowId game
  GameCache.cachePutGame gameCache game gameIOEitherLifter
  return game

-- | Service function to commit a user play - reflecting it on the
--   game's board, and and refilling the user tray.
--   Return the newly added replenishment pieces to the user tray.
commitPlayService ::
     String
  -> [PlayPiece]
  -> GameTransformerStack [Piece]

commitPlayService gmId playPieces = do
  GameEnv { config, gameCache, dictionaryCache } <- ask
  game @ Game {languageCode} <- GameCache.cacheFindGame gameCache gmId gameIOEitherLifter
  let playWord = PlayPiece.playPiecesToWord playPieces
  dictionary <- stringExceptLifter $ DictionaryCache.getDictionary dictionaryCache languageCode
  Dict.validateWord dictionary (BS.pack playWord)
  (game' @ Game {playNumber}, refills)
    <- Game.reflectPlayOnGame game UserPlayer playPieces
  saveWordPlay gmId playNumber UserPlayer playPieces refills
  GameCache.cachePutGame gameCache game' gameIOEitherLifter
  return refills

-- TODO. Save the replacement pieces in the database.
-- TODO. Need to save the update game info in the DB.

-- | Service function to obtain the next machine play.
--   If no match is found, then the machine exchanges a piece.
machinePlayService :: String -> GameTransformerStack [PlayPiece]
machinePlayService gameId = do
  gameCache <- asks GameEnv.gameCache
  dictionaryCache <- asks GameEnv.dictionaryCache
  (game @ Game {gameId, languageCode, board, trays}) <- GameCache.cacheFindGame gameCache gameId gameIOEitherLifter
  dictionary <- stringExceptLifter $ DictionaryCache.getDictionary dictionaryCache languageCode
  let words = Dict.getAllWordsAsString dictionary
      machineTray = trays !! Player.machineIndex
      matches = BoardStripMatcher.findMatchesOnBoard words board machineTray
      maybeMatch = optimalMatch matches
  (game', machinePlayPieces) <- case maybeMatch of
    Nothing -> do
      gm <- exchangeMachinePiece game
      return (gm, []) -- If no pieces were used - we know it was a swap.
    Just Play.Play { playPieces } -> do
      (gm @ Game {playNumber}, refills) <- Game.reflectPlayOnGame game MachinePlayer playPieces
      saveWordPlay gameId playNumber MachinePlayer playPieces refills
      return (gm, playPieces)
  GameCache.cachePutGame gameCache game' gameIOEitherLifter
  return machinePlayPieces

-- TODO. Save the new game data in the database.
-- TODO. Would this be simpler with a stack of ExceptT May IO??
-- | Service function to swap a user piece for another.
swapPieceService :: String -> Piece -> GameTransformerStack Piece

swapPieceService gameId (piece @ (Piece {pieceId})) = do
  gameCache <- asks GameEnv.gameCache
  (game @ Game {gameId, board, trays}) <- GameCache.cacheFindGame gameCache gameId gameIOEitherLifter
  let (userTray @ (Tray {pieces})) = trays !! Player.userIndex
  index <- Tray.findPieceIndexById userTray pieceId
  let swappedPiece = pieces !! index
  (game' @ Game {playNumber}, newPiece) <- Game.doExchange game UserPlayer index
  saveSwap gameId playNumber UserPlayer swappedPiece newPiece
  GameCache.cachePutGame gameCache game' gameIOEitherLifter
  return newPiece

-- TODO. Must clear cache of abandoned games. As opposed to suspended games.
-- TODO. Need timeout for arrival of requests. Abandoned game should be resumable.
-- TODO. Implement suspension and resumption of games.

endGameService :: String -> GameTransformerStack ()
endGameService gameId = do
  gameCache <- asks GameEnv.gameCache
  GameCache.cacheRemoveGame gameCache gameId gameIOEitherLifter
  -- TODO. Tell the database that the game has ended - as opposed to suspended.


-- TODO. A swap is also a play and should increment the playNumber. For both machine and user.
-- TODO. play number needs to be updated at the right time.

-- | No matches available for machine - do a swap instead.
exchangeMachinePiece :: Game -> GameTransformerStack Game
exchangeMachinePiece (game @ Game.Game {gameId, board, trays, playNumber, ..}) = do
  piece <- liftIO Piece.mkRandomPiece -- TODO. Must get the piece from the game.
  let (machineTray @ Tray {pieces}) = trays !! Player.machineIndex
      (Just (_, index)) = Piece.leastFrequentLetter $ Piece.value <$> pieces
      swappedPiece = pieces !! index
      tray' = Tray.replacePiece machineTray index piece
  -- TODO. Update play number at the right place before using it here.
  saveSwap gameId playNumber UserPlayer swappedPiece piece
  return $ Game.setPlayerTray game MachinePlayer tray'

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
  gameRowId <- GameDao.findExistingGameRowIdByGameId gameId
  let playRow = PlayRow gameRowId playNumber (show playerType) isPlay details
  GameDao.addPlay playRow

-- TODO. More intelligent optimal match based on values of moved pieces.
optimalMatch :: [Play] -> Maybe Play
optimalMatch matches =
  if null matches
    then Nothing
    else Just $ maximumBy (comparing (length . Play.playPieces)) matches

gameToRow :: PlayerRowId -> Game -> GameRow
gameToRow playerId game =
  GameRow gameId playerId (Board.height board) (Board.width board) trayCapacity
    where Game {gameId, board , trays, playerName} = game
          trayCapacity = length $ Tray.pieces (trays !! Player.userIndex) -- TODO. Just use tray capacity.

playerToRow :: Player.Player -> PlayerRow
playerToRow player = PlayerRow $ Player.name player -- TODO. Clean this up.

getGamePlayDetailsService :: String -> GameTransformerStack [PlayInfo]
getGamePlayDetailsService gameId = do
  playRows <- GameDao.getGamePlays gameId
  return $ playRowToPlayInfo <$> playRows

-- TODO. Check for decode returning Nothing - error in decoding.

playRowToPlayInfo :: PlayRow -> PlayInfo
playRowToPlayInfo PlayRow {playRowNumber, playRowTurn, playRowIsPlay, playRowDetails} =
  let maybePlayDetails = PlayDetails.decode playRowDetails
  in PlayInfo playRowNumber (read playRowTurn) (fromJust maybePlayDetails)

