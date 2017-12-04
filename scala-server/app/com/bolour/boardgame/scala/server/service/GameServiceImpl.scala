/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service


import javax.inject.Inject

import scala.collection.mutable.{Map => MutableMap}
import com.typesafe.config.Config
import com.bolour.util.BasicUtil.{ID, readConfigStringList}
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.PlayerType._
import com.bolour.boardgame.scala.common.domain.Piece.Pieces
import com.bolour.boardgame.scala.common.domain.Piece.noPiece
import com.bolour.boardgame.scala.common.domain.PlayPieceObj.PlayPieces
import com.bolour.boardgame.scala.server.domain._
import com.bolour.boardgame.scala.server.domain.GameExceptions._
import com.bolour.boardgame.scala.server.domain.WordDictionary.readDictionary
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

  // TODO. Validate all config parameters and throw meaningful exceptions.

  // TODO. Validate service method parameters.
  // To the extent validation code is implementation-independent,
  // implement in the base trait.

  val dictionaryDirConfigPath = confPath("dictionaryDir")

  val maxActiveGames = config.getInt(maxActiveGamesConfigPath)
  val dictionaryDir = config.getString(dictionaryDirConfigPath)

  readConfigStringList(languageCodesConfigPath) match {
    case Failure(ex) => throw ex
    case Success(languageCodes) =>
      languageCodes.foreach {
        languageCode =>
          readDictionary(languageCode, dictionaryDir) match {
            case Failure(ex) => throw new MissingDictionaryException(languageCode, dictionaryDir, ex)
            case Success(dictionary) =>
              logger.info(s"adding language dictionary: ${languageCode}")
              dictionaryCache(languageCode) = dictionary
          }
      }
  }

  val defaultDb = config.getString(defaultDbPath)
  val gameDao = GameDaoSlick(defaultDb, config)

  val seedPlayerName = "You"
  val seedPlayer = Player(seedPlayerName)

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
    gridPieces: List[GridPiece],      // For testing only.
    initUserPieces: List[Piece],      // For testing only.
    initMachinePieces: List[Piece]    // For testing only.
  ): Try[GameState] = {
    if (gameCache.size >= maxActiveGames)
      return Failure(SystemOverloadedException())

    val pieceGenerator = PieceGenerator(gameParams.pieceGeneratorType)
    for {
      player <- getPlayerByName(gameParams.playerName)
      game = Game(gameParams, player.id, pieceGenerator)
      gameState = GameState(game, gameParams, gridPieces, initUserPieces, initMachinePieces)
      _ <- gameDao.addGame(game)
      _ = gameCache.put(game.id, gameState)
      // machinePlayPieces <- machinePlay(game.id)
      // logger.info(s"machine play initial word: ${machinePlayPieces.map(_.piece.value).mkString}")
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

  override def commitPlay(gameId: String, playPieces: List[PlayPiece]): Try[List[Piece]] = {
    val os = gameCache.get(gameId)
    if (os.isEmpty)
      return Failure(MissingGameException(gameId))

    val state = os.get
    val word = PlayPieceObj.playPiecesToWord(playPieces)
    val languageCode = state.game.languageCode

    val od = dictionaryCache.get(languageCode)
    if (od.isEmpty)
      return Failure(UnsupportedLanguageException(languageCode))

    if (!od.get.hasWord(word))
      return Failure(InvalidWordException(languageCode, word))

    for {
      (newState, refills) <- state.addPlay(UserPlayer, playPieces)
      // TODO. How to eliminate dummy values entirely in for.
      _ <- savePlay(newState, playPieces, refills)
      _ = gameCache += ((gameId, newState))
    } yield (refills)
  }

  // TODO. Persist play.
  private def savePlay(gameState: GameState, playPieces: PlayPieces, replacements: Pieces): Try[Unit] = {
    Success(())
  }

  // TODO. Implement machine play.
  override def machinePlay(gameId: String): Try[List[PlayPiece]] = {
    val os = gameCache.get(gameId)
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
          _ = gameCache +=((gameId, newState))
        } yield Nil
      case playPieces =>
        for {
          (newState, refills) <- state.addPlay(UserPlayer, playPieces)
          // TODO. How to eliminate dummy values entirely in for.
          _ <- savePlay(newState, playPieces, refills)
          _ = gameCache += ((gameId, newState))
        } yield playPieces
    }
  }

  private def exchangeMachinePiece(state: GameState): Try[GameState] = {
    val tray = state.tray(MachinePlayer)
    val letter = Piece.leastFrequentLetter(tray.letters).get
    val swappedPiece = tray.findPieceByLetter(letter).get
    implicit val pieceGenerator = state.game.pieceGenerator
    for {
      (newPiece, newTray) <- tray.swapPiece(swappedPiece)
      newTrays: List[Tray] = state.trays.updated(playerIndex(MachinePlayer), newTray)
      newState = state.copy(trays = newTrays)
      _ = saveSwap(state.game.id, state.playNumber, MachinePlayer, swappedPiece, newPiece)
    } yield newState
  }

  private def saveSwap(gameId: String, playNumber: Int, playerType: PlayerType, swappedPiece: Piece, newPiece: Piece): Try[Unit] =
    Success(()) // TODO. Implement saveSwap.

  override def swapPiece(gameId: String, piece: Piece): Try[Piece] = {
    val os = gameCache.get(gameId)
    os match {
      case None => Failure(MissingGameException(gameId))
      case Some(state) =>
        val userTray: Tray = state.tray(UserPlayer)
        implicit val gen = state.game.pieceGenerator
        for {
          (newPiece, newUserTray) <- userTray.swapPiece(piece)
          newState = state.copy(trays = state.trays.updated(playerIndex(UserPlayer), newUserTray))
          _ = gameCache.put(gameId, newState)
          _ = saveSwap(state.game.id, state.playNumber, MachinePlayer, piece, newPiece)
        } yield (newPiece)
    }
  }

  override def endGame(gameId: String): Try[Unit] = {
    val maybeState = gameCache.get(gameId)
    maybeState match {
      case None => Failure(MissingGameException(gameId))
      case Some(_) => {
        gameCache.remove(gameId)
        gameDao.endGame(gameId)
      }
    }
  }

  // TODO. Check the cache first for the game.
  // TODO. Get the correct piece generator for the game. For now using cyclic.
  override def findGameById(gameId: ID): Try[Option[Game]] =
    gameDao.findGameById(gameId)(PieceGenerator.CyclicPieceGenerator())
}

object GameServiceImpl {
  val gameCache: MutableMap[String, GameState] = MutableMap()
  val dictionaryCache: MutableMap[String, WordDictionary] = MutableMap()
}