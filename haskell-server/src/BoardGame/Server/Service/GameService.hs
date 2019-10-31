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
  , timeoutLongRunningGames
  , prepareDb
  , unknownPlayerName
  )
  where

-- import Data.Ord
-- import Data.List
import Data.Maybe (fromJust, isNothing)
import Data.Time (getCurrentTime)
import Data.Bool (bool)
import qualified Data.Map as Map

import Control.Monad (when, unless)
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..), withExceptT)
import Control.Monad.Trans.Except (ExceptT)
import Control.Monad.Reader (MonadReader(..), asks, ask)
import Control.Monad.Trans.Class (lift)

import Bolour.Util.MiscUtil (isAlphaNumString)
-- import Bolour.Util.Core (EntityId)
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
-- import BoardGame.Common.Domain.PiecePoint (PiecePoint)
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(..))
-- import qualified BoardGame.Common.Domain.GameParams as GameParams

import qualified BoardGame.Server.Domain.ServerVersion as ServerVersion
import BoardGame.Server.Domain.Game (Game, Game(Game))
import qualified BoardGame.Server.Domain.Game as Game
-- import BoardGame.Server.Domain.GameBase (GameBase, GameBase(GameBase))
import qualified BoardGame.Server.Domain.GameBase as GameBase
import BoardGame.Common.Domain.InitPieces (InitPieces, InitPieces(InitPieces))
import qualified BoardGame.Common.Domain.InitPieces as InitPieces

import BoardGame.Server.Domain.GameBase (GameBase(GameBase))
-- import qualified BoardGame.Server.Domain.GameBase as GameBase
import BoardGame.Server.Domain.GameError (GameError(..))
import BoardGame.Server.Domain.Tray (Tray(Tray))
import qualified BoardGame.Server.Domain.Tray as Tray
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.GameCache as GameCache
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
import BoardGame.Server.Domain.GameEnv (GameEnv(..))
import BoardGame.Server.Service.GameTransformerStack (GameTransformerStack, exceptTToStack)
import qualified BoardGame.Server.Domain.GameEnv as GameEnv (GameEnv(..))
import BoardGame.Server.Domain.ServerConfig as ServerConfig
import qualified BoardGame.Server.Domain.StripMatcher as Matcher
import qualified BoardGame.Server.Domain.Strip as Strip
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip))
import BoardGame.Server.Domain.PieceProvider (PieceProvider(..))
import qualified BoardGame.Server.Service.GameLetterDistribution as GameLetterDistribution
import BoardGame.Server.Service.GameData (GameData, GameData(GameData))
import qualified BoardGame.Server.Service.GameData as GameData

import BoardGame.Server.Service.GamePersister (GamePersister, GamePersister(GamePersister))
import qualified BoardGame.Server.Service.GamePersister as GamePersister
import qualified BoardGame.Server.Service.GamePersisterJsonBridge as GamePersisterJsonBridge
import qualified BoardGame.Server.Service.GameJsonSqlPersister as GameJsonSqlPersister
-- import qualified BoardGame.Server.Service.GameJsonSqlPersister as GamePersister

mkPersister :: GameTransformerStack GamePersister
mkPersister = do
  connectionProvider <- asks GameEnv.connectionProvider
  let jsonPersister = GameJsonSqlPersister.mkPersister connectionProvider
      version = ServerVersion.version
  return $ GamePersisterJsonBridge.mkBridge jsonPersister version

unknownPlayerName = "You"
-- unknownPlayer = Player unknownPlayerName

-- | Convert game data stored in the database to a game domain object.
--   Important. The game's piece provider depends on specific parameters
--   that are not stored in the database (for simplicity).
--   It is assumed that these parameters are immutable constants over
--   versions of the system. They are defined in this module.
--   Furthermore, the state of a piece provider changes during the
--   the game, and that state is also not tracked in the database.
--   So the state of the piece provider in a restored game may be
--   different than that of the saved game. For the use cases of
--   our current piece providers this is not a major issue.
--   Random piece providers should function as expected. And
--   cyclic piece providers are only used in testing.
gameFromData :: GameData -> Game
gameFromData GameData {base, plays} =
  let GameBase {gameParams} = base
      GameParams {pieceProviderType} = gameParams
      pieceProvider = mkPieceProvider pieceProviderType
      game = Game.mkStartingGame base pieceProvider
      -- TODO. Update the state of the game using the plays.
  in Game.setPlays game plays

-- | Convert a game domain object to its db-storable representation.
--   Note that the parameters of the piece provider of the game
--   are not stored in the database. For now the potential change
--   of these parameters over time is a non-requirement.
dataFromGame :: Game -> GameData
dataFromGame Game {gameBase, plays} = GameData gameBase plays

prepareDb :: GameTransformerStack ()
prepareDb = do
  GamePersister {migrate} <- mkPersister
  exceptTToStack migrate
  addPlayerIfAbsentService unknownPlayerName

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

existsOk = True
existsNotOk = not existsOk

saveNamedPlayer :: String -> Bool -> GameTransformerStack ()
saveNamedPlayer name existsOk = do
  persister @ GamePersister {addPlayer, findPlayerByName} <- mkPersister
  maybePlayer <- exceptTToStack $ findPlayerByName name
  case maybePlayer of
    Nothing -> do
      playerId <- liftIO Util.mkUuid
      let player = Player playerId name
      exceptTToStack $ addPlayer player
    _ -> unless existsOk $ throwError $ PlayerNameExistsError name

-- | Service function to add a player to the system - error if name exists.
addPlayerService :: String -> GameTransformerStack ()
addPlayerService name =
  if isAlphaNumString name then
    saveNamedPlayer name existsNotOk
  else
    throwError $ InvalidPlayerNameError name

-- | Service function to add a player if not present - no-op if nae exists.
addPlayerIfAbsentService :: String -> GameTransformerStack ()
addPlayerIfAbsentService name =
  if isAlphaNumString name then
    saveNamedPlayer name existsOk
  else
    throwError $ InvalidPlayerNameError name

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
     GameParams   -- Basic game parameters - dimension, etc.
  -> InitPieces   -- Initial pieces in trays and on board - for testing.
  -> [[Int]]      -- Values assigned to the board's points for scoring.
  -> GameTransformerStack Game

startGameService gameParams initPieces pointValues = do
  -- TODO. Validate parameters. Point values must be a dimension x dimension matrix.
  params <- Game.validateGameParams gameParams
  let GameParams {dimension, languageCode, pieceProviderType, playerName} = params
  let InitPieces {userPieces, machinePieces} = initPieces
  GameEnv { gameCache } <- ask
  persister @ GamePersister {findPlayerByName} <- mkPersister
  maybePlayer <- exceptTToStack $ findPlayerByName playerName
  case maybePlayer of
    Nothing -> throwError $ MissingPlayerError playerName
    Just player -> do
      let pieceProvider = mkPieceProvider pieceProviderType
      game <- Game.mkInitialGame params initPieces pieceProvider pointValues player
      persistGame game
      exceptTToStack $ GameCache.insert game gameCache
      return game

restoreGameService :: String -> GameTransformerStack (Maybe Game)
restoreGameService gameId = do
  persister @ GamePersister {findGameById} <- mkPersister
  maybeGameData <- exceptTToStack $ findGameById gameId
  return $ gameFromData <$> maybeGameData

persistGame :: Game -> GameTransformerStack ()
persistGame game = do
  persister <- mkPersister
  exceptTToStack $ GamePersister.saveGame persister $ dataFromGame game

validateCrossWords :: Board -> WordDictionary -> Strip -> String -> GameTransformerStack ()
validateCrossWords board dictionary strip word = do
  let crosswords = CrossWordFinder.findStripCrossWords board strip word
      invalidCrosswords = filter (not . Dict.isWord dictionary) crosswords
  bool (throwError $ InvalidCrossWordError invalidCrosswords) (return ()) (null invalidCrosswords)

-- | Service function to commit a user play - reflecting it on the
--   game's board, and and refilling the user tray.
--   Return the newly added replenishment pieces to the user tray.
commitPlayService ::
     String
  -> [PlayPiece]
  -> GameTransformerStack (GameMiniState, [Piece], [Point])

commitPlayService gameId playPieces = do
  GameEnv { gameCache } <- ask
  game @ Game {gameBase, board} <- exceptTToStack $ GameCache.lookup gameId gameCache
  let GameBase {gameParams} = gameBase
      GameParams {languageCode} = gameParams
      playWord = PlayPiece.playPiecesToWord playPieces
  dictionary <- lookupDictionary languageCode
  unless (Dict.isWord dictionary playWord) $
    throwError $ InvalidWordError playWord
  let maybeStrip = Board.stripOfPlay board playPieces
  when (isNothing maybeStrip) $
    throwError $ WordTooShortError playWord
  let Just strip = maybeStrip
  validateCrossWords board dictionary strip playWord
  let blackPointFinder = Matcher.findAndSetBoardBlackPoints dictionary
  (game', refills, deadPoints)
    <- Game.reflectPlayOnGame game UserPlayer playPieces blackPointFinder
  persistGame game'
  exceptTToStack $ GameCache.insert game' gameCache
  let miniState = Game.toMiniState game'
  return (miniState, refills, deadPoints)

-- | Service function to obtain the next machine play.
--   If no match is found, then the machine exchanges a piece.
machinePlayService :: String -> GameTransformerStack (GameMiniState, [PlayPiece], [Point])
machinePlayService gameId = do
  GameEnv { gameCache } <- ask
  (game @ Game {gameBase, board, trays}) <- exceptTToStack $ GameCache.lookup gameId gameCache
  let gameId = Game.gameId game
      GameBase {gameParams} = gameBase
      GameParams {languageCode} = gameParams
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
      let blackPointFinder = Matcher.findAndSetBoardBlackPoints dictionary
      (gm, refills, deadPoints)
        <- Game.reflectPlayOnGame game MachinePlayer playPieces blackPointFinder
      return (gm, playPieces, deadPoints)
  persistGame game'
  exceptTToStack $ GameCache.insert game' gameCache
  let miniState = Game.toMiniState game'
  return (miniState, machinePlayPieces, deadPoints)

-- | Service function to swap a user piece for another.
swapPieceService :: String -> Piece -> GameTransformerStack (GameMiniState, Piece)

swapPieceService gameId (piece @ Piece {id}) = do
  gameCache <- asks GameEnv.gameCache
  (game @ Game {trays}) <- exceptTToStack $ GameCache.lookup gameId gameCache
  let gameId = Game.gameId game
      (userTray @ Tray {pieces}) = trays !! Player.userIndex
  index <- Tray.findPieceIndexById userTray id
  let swappedPiece = pieces !! index
  (game', newPiece) <- Game.doExchange game UserPlayer index
  exceptTToStack $ GameCache.insert game' gameCache
  persistGame game'
  let miniState = Game.toMiniState game'
  return (miniState, newPiece)

-- | No matches available for machine - do a swap instead.
exchangeMachinePiece :: Game -> GameTransformerStack Game
exchangeMachinePiece (game @ Game {trays}) = do
  let gameId = Game.gameId game
      (machineTray @ Tray {pieces}) = trays !! Player.machineIndex
  if Tray.isEmpty machineTray
    then return game
    else do
      let piece @ Piece { id } = head pieces
      index <- Tray.findPieceIndexById machineTray id
      (game', newPiece) <- Game.doExchange game MachinePlayer index
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

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

mkPieceProvider :: PieceProviderType -> PieceProvider
mkPieceProvider PieceProviderType.Random =
  let randomizer = FrequencyDistribution.randomValue letterDistribution
  in RandomPieceProvider 0 randomizer
mkPieceProvider PieceProviderType.Cyclic = CyclicPieceProvider 0 (cycle caps)
