/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service


import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject

import scala.collection.mutable.{Map => MutableMap}
import com.typesafe.config.Config
import com.bolour.util.scala.common.CommonUtil.ID
import com.bolour.util.scala.server.BasicServerUtil.readConfigStringList
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.PlayerType._
import com.bolour.boardgame.scala.common.domain.Piece.Pieces
import com.bolour.boardgame.scala.common.domain.PlayPieceObj.PlayPieces
import com.bolour.boardgame.scala.server.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions._
import com.bolour.language.scala.domain.WordDictionary
import com.bolour.plane.scala.domain.Point
import org.slf4j.LoggerFactory

import scala.collection.immutable.Nil
import scala.collection.mutable
import scala.util.{Failure, Success, Try}

class GameServiceImpl @Inject() (config: Config) extends GameService {

  import GameService._
  import GameServiceImpl._

  val logger = LoggerFactory.getLogger(this.getClass)

  val dbConfigPrefix = confPath("db")
  val defaultDbPath = s"${dbConfigPrefix}.defaultDb"
  val MaxMaskedLetters = 3

  // TODO. Validate all config parameters and throw meaningful exceptions.

  // TODO. Validate service method parameters.
  // To the extent validation code is implementation-independent,
  // implement in the base trait.

  val dictionaryDirConfigPath = confPath("dictionaryDir")

  val maxActiveGames = config.getInt(maxActiveGamesConfigPath)
  val maxGameMinutes = config.getInt(maxGameMinutesConfigPath)
  val dictionaryDir = config.getString(dictionaryDirConfigPath)

  readConfigStringList(languageCodesConfigPath) match {
    case Failure(ex) => throw ex
    case Success(languageCodes) =>
      languageCodes.foreach {
        languageCode =>
          WordDictionary.mkWordDictionary(languageCode, dictionaryDir, MaxMaskedLetters) match {
            case Failure(ex) => throw convertException(ex)
            case Success(dictionary) =>
              logger.info(s"adding language dictionary: ${languageCode}")
              dictionaryCache(languageCode) = dictionary
          }
      }
  }

  private def convertException(ex: Throwable): GameException = {
    ex match {
      case com.bolour.language.scala.domain.LanguageExceptions.MissingDictionaryException(languageCode, dictionaryDir, ex) =>
        MissingDictionaryException(languageCode, dictionaryDir, ex)
      case _ => InternalGameException("unable to make word dictionary", ex)
    }
  }

  val defaultDb = config.getString(defaultDbPath)
  // val gameDao: GameDao = GameDaoSlick(defaultDb, config)
  val gameDao: GameDao = new GameDaoMock

  val seedPlayerName = "You"
  val seedPlayer = Player(seedPlayerName)

  migrate()

  override def migrate() = {
    // TODO. Proper migration. This one is for testing only.
    // Version the server - and create an upgrade function for each new version.
    // Keep last upgraded version in the database.
    for /* try */ {
      _ <- gameDao.createNonExistentTables()
      maybeSeedPlayer <- gameDao.findPlayerByName(seedPlayerName)
      _ <- maybeSeedPlayer match {
        case None => gameDao.addPlayer(seedPlayer)
        case _ => Success(())
      }
    } yield ()

  }

  override def reset() = {
    gameDao.cleanupDb()
  }

  override def addPlayer(player: Player): Try[Unit] = gameDao.addPlayer(player)

  // TODO. Check params.
  // Dimension >= 5 <= 30.
  // Tray capacity > 0 < 20.
  // language code - needs supported languages.
  // player name not empty - alphanumeric.
  override def startGame(
    gameParams: GameParams,
    gridPieces: List[PiecePoint],      // For testing only.
    initUserPieces: List[Piece],      // For testing only.
    initMachinePieces: List[Piece],    // For testing only.
    pointValues: List[List[Int]]
  ): Try[Game] = {
    if (gameCache.size >= maxActiveGames)
      return Failure(SystemOverloadedException())

    for {
      player <- getPlayerByName(gameParams.playerName)
      game = GameInitialState(gameParams, pointValues, player.id)
      gameState <- Game.mkGameState(game, gridPieces, initUserPieces, initMachinePieces)
      _ <- gameDao.addGame(game)
      _ = gameCache.put(game.id, gameState)
    } yield gameState
    // } yield (gameState, Some(machinePlayPieces))
  }

  private def getPlayerByName(playerName: String): Try[Player] = {
    val tried = gameDao.findPlayerByName(playerName)
    tried match {
      case Failure(err) => Failure(err)
      case Success(maybePlayer) =>
        maybePlayer match {
          case None => Failure(MissingPlayerException(playerName))
          case Some(player) => Success(player)
        }
    }
  }

  override def commitPlay(gameId: String, playPieces: List[PlayPiece]): Try[(GameMiniState, List[Piece], List[Point])] = {
    val os = Option(gameCache.get(gameId))
    if (os.isEmpty)
      return Failure(MissingGameException(gameId))

    val state = os.get
    val word = PlayPieceObj.playPiecesToWord(playPieces)
    val languageCode = state.game.languageCode

    val od = dictionaryCache.get(languageCode)
    if (od.isEmpty)
      return Failure(UnsupportedLanguageException(languageCode))

    val dictionary = od.get

    val userTray = state.trays(playerIndex(UserPlayer))

    // TODO. Should validate the play here.

    if (!dictionary.hasWord(word))
      return Failure(InvalidWordException(languageCode, word))

    for {
      _ <- state.checkCrossWords(playPieces, dictionary)
      (newState, refills) <- state.addPlay(UserPlayer, playPieces)
      (newBoard, deadPoints) = updateDeadPoints(newState.board, od.get)
      finalState = newState.copy(board = newBoard)
      _ <- savePlay(newState, playPieces, refills)
      _ = gameCache.put(gameId, newState)
    } yield (finalState.miniState, refills, deadPoints)
  }

  private def updateDeadPoints(board: Board, dictionary: WordDictionary): (Board, List[Point]) = {
    val directDeadPoints = StripMatcher.hopelessBlankPoints(board, dictionary).toList
    val newBoard = board.setBlackPoints(directDeadPoints)
    directDeadPoints match {
      case Nil => (newBoard, directDeadPoints)
      case _ =>
        val (b, moreDeadPoints) = updateDeadPoints(newBoard, dictionary)
        val allDeadPoints = directDeadPoints ++ moreDeadPoints
        (b, allDeadPoints)
    }
  }

  // TODO. Persist play.
  private def savePlay(gameState: Game, playPieces: PlayPieces, replacements: Pieces): Try[Unit] = {
    Success(())
  }

  override def machinePlay(gameId: String): Try[(GameMiniState, List[PlayPiece], List[Point])] = {
    val os = Option(gameCache.get(gameId))
    if (os.isEmpty)
      return Failure(MissingGameException(gameId))

    val state = os.get
    val languageCode = state.game.languageCode

    val od = dictionaryCache.get(languageCode)
    if (od.isEmpty)
      return Failure(UnsupportedLanguageException(languageCode))

    val machineTray = state.trays(playerIndex(MachinePlayer))
    // logger.info(s"machine play - tray has: ${machineTray.letters}")

    val stripMatcher = new StripMatcher {
      override def dictionary: WordDictionary = od.get
      override def board = state.board
      override def tray: Tray = machineTray
    }

    stripMatcher.bestMatch() match {
      case Nil =>
        for {
          newState <- exchangeMachinePiece(state)
          _ = gameCache.put(gameId, newState)
        } yield (newState.miniState, Nil, Nil)
      case playPieces =>
        for {
          (newState, refills) <- state.addPlay(MachinePlayer, playPieces)
          // deadPoints = StripMatcher.hopelessBlankPoints(newState.board, od.get, machineTray.capacity).toList
          // finalState = newState.setDeadPoints(deadPoints)
          (newBoard, deadPoints) = updateDeadPoints(newState.board, od.get)
          finalState = newState.copy(board = newBoard)
          // TODO. How to eliminate dummy values entirely in for.
          _ <- savePlay(finalState, playPieces, refills)
          _ = gameCache.put(gameId, newState)
        } yield (finalState.miniState, playPieces, deadPoints)
    }
  }

  private def exchangeMachinePiece(state: Game): Try[Game] = {
    val tray = state.tray(MachinePlayer)
    val letter = Piece.leastFrequentLetter(tray.letters).get
    val swappedPiece = tray.findPieceByLetter(letter).get
    for {
      (newState, newPiece) <- state.swapPiece(swappedPiece, MachinePlayer)
      _ = saveSwap(state.game.id, state.playNumber, MachinePlayer, swappedPiece, newPiece)
    } yield newState
  }

  private def saveSwap(gameId: String, playNumber: Int, playerType: PlayerType, swappedPiece: Piece, newPiece: Piece): Try[Unit] =
    Success(()) // TODO. Implement saveSwap.

  override def swapPiece(gameId: String, piece: Piece): Try[(GameMiniState, Piece)] = {
    val os = Option(gameCache.get(gameId))
    os match {
      case None => Failure(MissingGameException(gameId))
      case Some(state) =>
        for {
          (newState, newPiece) <- state.swapPiece(piece, UserPlayer)
          _ = gameCache.put(gameId, newState)
          _ = saveSwap(state.game.id, state.playNumber, UserPlayer, piece, newPiece)
        } yield (newState.miniState, newPiece)
    }
  }

  override def endGame(gameId: String): Try[GameSummary] = {
    val maybeState = Option(gameCache.get(gameId))
    maybeState match {
      case None => Failure(MissingGameException(gameId))
      case Some(state) => {
        gameCache.remove(gameId)
        gameDao.endGame(gameId)
        val finalState = state.stop()
        Success(finalState.summary())
      }
    }
  }

  // TODO. Check the cache first for the game.
  // TODO. Get the correct piece generator for the game. For now using cyclic.
  override def findGameById(gameId: ID): Try[Option[GameInitialState]] =
    gameDao.findGameById(gameId)

  def timeoutLongRunningGames(): Try[Unit] = Try {
    import scala.collection.JavaConverters._
    def aged(gameId: String): Boolean = {
      val maybeState = Option(gameCache.get(gameId))
      maybeState match {
        case None => false
        case Some(state) =>
          val startTime = state.game.startTime
          val now = Instant.now()
          val seconds = now.getEpochSecond - startTime.getEpochSecond
          seconds > (maxGameMinutes * 60)
      }
    }
    val gameIdList = gameCache.keys().asScala.toList
    val longRunningGameIdList = gameIdList filter { aged }
    // logger.info(s"games running more than ${maxGameMinutes}: ${longRunningGameIdList}")
    longRunningGameIdList.foreach(gameCache.remove(_))
  }
}

object GameServiceImpl {
  val gameCache: ConcurrentHashMap[String, Game] = new ConcurrentHashMap()
  val dictionaryCache: MutableMap[String, WordDictionary] = MutableMap()

  def cacheGameState(gameId: String, gameState: Game): Try[Unit] = Try {
    gameCache.put(gameId, gameState)
  }
}
