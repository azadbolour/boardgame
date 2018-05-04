/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service


import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject

import com.bolour.boardgame.scala.common.domain.PieceProviderType.PieceProviderType

import scala.collection.mutable.{Map => MutableMap}
import com.typesafe.config.Config
import com.bolour.util.scala.server.BasicServerUtil.stringId
import com.bolour.util.scala.common.CommonUtil.ID
import com.bolour.util.scala.server.BasicServerUtil.readConfigStringList
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.PlayerType._
import com.bolour.boardgame.scala.common.domain.PlayPieceObj.PlayPieces
import com.bolour.boardgame.scala.server.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions._
import com.bolour.language.scala.domain.WordDictionary
import com.bolour.plane.scala.domain.Point
import com.bolour.util.scala.common.FrequencyDistribution
import org.slf4j.LoggerFactory

import scala.collection.immutable.Nil
import scala.collection.mutable
import scala.util.{Failure, Success, Try}

/**
  * Implementation of the service layer.
  *
  * @param config The configuration of the game service.
  */
class GameServiceImpl @Inject() (config: Config) extends GameService {

  import GameService._
  import GameServiceImpl._
  import StripMatcher.findAndSetBoardBlackPoints

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
  // val persister: GamePersister = new GamePersisterJsonImpl(new GameJsonPersisterMemoryImpl(), Version.version)
  val persister: GamePersister = new GamePersisterJsonImpl(GameJsonPersisterSlickImpl(defaultDb, config), Version.version)

  val seedPlayerName = "You"
  val seedPlayer = Player(stringId, seedPlayerName)

  migrate()

  override def migrate() = {
    // TODO. Proper migration. This one is for testing only.
    // Version the server - and create an upgrade function for each new version.
    // Keep last upgraded version in the database.
    for /* try */ {
      _ <- persister.migrate()
      maybeSeedPlayer <- persister.findPlayerByName(seedPlayerName)
      _ <- maybeSeedPlayer match {
        case None => persister.savePlayer(seedPlayer)
        case _ => Success(())
      }
    } yield ()

  }

  override def reset() = {
    persister.clearAllData()
  }

  override def addPlayer(player: Player): Try[Unit] = persister.savePlayer(player)

  // TODO. Check params.
  // Dimension >= 5 <= 30.
  // Tray capacity > 0 < 20.
  // language code - needs supported languages.
  // player name not empty - alphanumeric.
  override def startGame(
    gameParams: GameParams,
    initPieces: InitPieces,
    pointValues: List[List[Int]]
  ): Try[Game] = {
    if (gameCache.size >= maxActiveGames)
      return Failure(SystemOverloadedException())

    val pieceProvider: PieceProvider = mkPieceProvider(gameParams.pieceProviderType)

    for {
      player <- getPlayerByName(gameParams.playerName)
      gameBase = GameBase(gameParams, initPieces, pointValues, player.id)
      game <- Game.mkGame(gameBase, pieceProvider)
      _ <- saveGame(game)
      _ = gameCache.put(gameBase.gameId, game)
    } yield game
    // } yield (gameState, Some(machinePlayPieces))
  }

  private def getPlayerByName(playerName: String): Try[Player] = {
    val tried = persister.findPlayerByName(playerName)
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
    val ogame = Option(gameCache.get(gameId))
    if (ogame.isEmpty)
      return Failure(MissingGameException(gameId))

    val game = ogame.get
    val word = PlayPieceObj.playPiecesToWord(playPieces)
    val languageCode = game.gameBase.gameParams.languageCode

    val odict = dictionaryCache.get(languageCode)
    if (odict.isEmpty)
      return Failure(UnsupportedLanguageException(languageCode))

    val dict = odict.get

    // TODO. Move all business logic validations to game.

    if (!dict.hasWord(word))
      return Failure(InvalidWordException(languageCode, word))

    for {
      _ <- game.checkCrossWords(playPieces, dict)
      (newGame, refills, deadPoints)
        <- game.addWordPlay(UserPlayer, playPieces, findAndSetBoardBlackPoints(odict.get))
      _ <- saveGame(newGame)
      _ = gameCache.put(gameId, newGame)
    } yield (newGame.miniState, refills, deadPoints)
  }

  override def machinePlay(gameId: String): Try[(GameMiniState, List[PlayPiece], List[Point])] = {
    val ogame = Option(gameCache.get(gameId))
    if (ogame.isEmpty)
      return Failure(MissingGameException(gameId))

    val game = ogame.get
    val languageCode = game.gameBase.gameParams.languageCode

    val odict = dictionaryCache.get(languageCode)
    if (odict.isEmpty)
      return Failure(UnsupportedLanguageException(languageCode))

    val dict = odict.get
    val machineTray = game.trays(playerIndex(MachinePlayer))

    val stripMatcher = new StripMatcher {
      override def dictionary: WordDictionary = dict
      override def board: Board = game.board
      override def tray: Tray = machineTray
    }

    val playPieces = stripMatcher.bestMatch()

     for {
      (newGame, deadPoints) <- playPieces match {
        case Nil => for {
            newGame <- swapMachinePiece(game)
          } yield (newGame, Nil)
        case _ => for {
          (newGame, _, deadPoints)
          <- game.addWordPlay(MachinePlayer, playPieces, findAndSetBoardBlackPoints(dict))
        } yield (newGame, deadPoints)
      }
      _ <- saveGame(newGame)
      _ = gameCache.put(gameId, newGame)
    } yield (newGame.miniState, playPieces, deadPoints)
    // TODO. How to eliminate dummy values entirely in for.
  }

  //
  //    stripMatcher.bestMatch() match {
  //      case Nil =>
  //        for {
  //          newGame <- swapMachinePiece(game)
  //          _ <- saveGame(newGame)
  //          _ = gameCache.put(gameId, newGame)
  //        } yield (newGame.miniState, Nil, Nil)
  //      case playPieces =>
  //        for {
  //          (newGame, _, deadPoints)
  //            <- game.addWordPlay(MachinePlayer, playPieces, findAndSetBoardBlackPoints(dict))
  //          // TODO. How to eliminate dummy values entirely in for.
  //          _ <- saveGame(newGame)
  //          _ = gameCache.put(gameId, newGame)
  //        } yield (newGame.miniState, playPieces, deadPoints)
  //    }

  private def swapMachinePiece(game: Game): Try[Game] = {
    val tray = game.tray(MachinePlayer)
    val letter = letterDistribution.leastFrequentValue(tray.letters.toList).get
    val swappedPiece = tray.findPieceByLetter(letter).get
    for {
      (newGame, _) <- game.addSwapPlay(swappedPiece, MachinePlayer)
    } yield newGame
  }

  override def swapPiece(gameId: String, piece: Piece): Try[(GameMiniState, Piece)] = {
    val ogame = Option(gameCache.get(gameId))
    ogame match {
      case None => Failure(MissingGameException(gameId))
      case Some(game) =>
        for {
          (newGame, newPiece) <- game.addSwapPlay(piece, UserPlayer)
          _ = gameCache.put(gameId, newGame)
          _ = saveGame(newGame)
        } yield (newGame.miniState, newPiece)
    }
  }

  override def endGame(gameId: String): Try[GameSummary] = {
    val ogame = Option(gameCache.get(gameId))
    ogame match {
      case None => Failure(MissingGameException(gameId))
      case Some(game) => {
        val endedGame = game.end()
        gameCache.remove(gameId)
        saveGame(endedGame)

        /*
         * Purging ended games to minimize DB space needs in containers.
         * TODO. Do not purge games immediately.
         * Future. Use a database external to the container.
         * Or map the database files to an external host system volume.
         */
        persister.deleteGame(gameId)

        val finalState = game.stop()
        Success(finalState.summary())
      }
    }
  }

  // TODO. Check the cache first for the game.
  // TODO. Get the correct piece generator for the game. For now using cyclic.
  override def findGameById(gameId: ID): Try[Option[Game]] = {
    for {
      maybeGameData: Option[GameData] <- persister.findGameById(gameId)
      maybeGame: Option[Game] <- maybeGameData match {
        case None => Success(None)
        case Some(gameData) =>
          GameData.toGame(gameData) match {
            case Failure(ex) => Failure(ex)
            case Success(game) => Success(Some(game))
          }
      }
    } yield maybeGame
  }

  def timeoutLongRunningGames(): Try[Unit] = Try {
    import scala.collection.JavaConverters._
    def aged(gameId: String): Boolean = {
      val ogame = Option(gameCache.get(gameId))
      ogame match {
        case None => false
        case Some(game) =>
          val startTime = game.gameBase.startTime
          val now = Instant.now()
          val seconds = now.getEpochSecond - startTime.getEpochSecond
          seconds > (maxGameMinutes * 60)
      }
    }
    val gameIdList = gameCache.keys().asScala.toList
    val longRunningGameIdList = gameIdList filter { aged }
    // logger.info(s"games running more than ${maxGameMinutes}: ${longRunningGameIdList}")
    longRunningGameIdList.foreach(endGame)
  }

  private def saveGame(game: Game) : Try[Unit] = {
    val gameData = GameData.fromGame(game)
    persister.saveGame(gameData)
  }
}

object GameServiceImpl {
  val gameCache: ConcurrentHashMap[String, Game] = new ConcurrentHashMap()
  val dictionaryCache: MutableMap[String, WordDictionary] = MutableMap()

  def cacheGameState(gameId: String, gameState: Game): Try[Unit] = Try {
    gameCache.put(gameId, gameState)
  }

  val letterFrequencies = List(
    ('A', 81),
    ('B', 15),
    ('C', 28),
    ('D', 42),
    ('E', 127),
    ('F', 22),
    ('G', 20),
    ('H', 61),
    ('I', 70),
    ('J', 2),
    ('K', 8),
    ('L', 40),
    ('M', 24),
    ('N', 67),
    ('O', 80),
    ('P', 19),
    ('Q', 1),
    ('R', 60),
    ('S', 63),
    ('T', 91),
    ('U', 28),
    ('V', 10),
    ('W', 23),
    ('X', 2),
    ('Y', 20),
    ('Z', 1)
  )

  val letterDistribution = FrequencyDistribution(letterFrequencies)

  def mkPieceProvider(pieceProviderType: PieceProviderType): PieceProvider = {
    pieceProviderType match {
      case PieceProviderType.Random => RandomPieceProvider(letterDistribution.randomValue _)
      case PieceProviderType.Cyclic => CyclicPieceProvider()
    }

  }

}
