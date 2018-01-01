/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.PlayerType.{playerIndex, _}
import com.bolour.boardgame.scala.server.domain.GameExceptions.{InvalidCrosswordsException, MalformedPlayException}
import org.slf4j.LoggerFactory

import scala.util.{Success, Try}

case class GameState(
  game: Game,
  board: Board,
  trays: List[Tray],
  tileSack: TileSack,
  playNumber: Int,
  playTurn: PlayerType,
  lastPlayScore: Int,
  numSuccessivePasses: Int,
  scores: List[Int]
) {
  import GameState.MaxSuccessivePasses

  val logger = LoggerFactory.getLogger(this.getClass)

  def passesMaxedOut: Boolean = numSuccessivePasses == MaxSuccessivePasses
  def isSackEmpty: Boolean = tileSack.isEmpty
  def isUserTrayEmpty: Boolean = trays(playerIndex(UserPlayer)).isEmpty
  def isMachineTrayEmpty: Boolean = trays(playerIndex(MachinePlayer)).isEmpty

  /**
    * Play stops when either the maximum number of passes (plays with no score)
    * is reached, or when there are no more tiles in the sack and one of the
    * players has used up all his tiles.
    */
  def noMorePlays: Boolean = passesMaxedOut || (isSackEmpty && (isUserTrayEmpty || isMachineTrayEmpty))

  def miniState: GameMiniState =
    GameMiniState(lastPlayScore, scores, tileSack.length, noMorePlays)

  def stopInfo: StopInfo = StopInfo(numSuccessivePasses, MaxSuccessivePasses, isSackEmpty, isUserTrayEmpty, isMachineTrayEmpty)

  // TODO. May fail. So return a Try for consistency.
  def stop(): (GameState, List[Int]) = {
    val userSum = trays(playerIndex(UserPlayer)).sumLetterWorths
    val machineSum = trays(playerIndex(MachinePlayer)).sumLetterWorths
    def bonus(thisSum: Int, thatSum: Int): Int = if (thisSum > 0) -thisSum else thatSum
    val userBonus = bonus(userSum, machineSum)
    val machineBonus = bonus(machineSum, userSum)
    val endOfPlayScores = List(userBonus, machineBonus)
    val finalScores = (scores zip endOfPlayScores) map { both => both._1 + both._2 }
    val newState = this.copy(scores = finalScores)
    (newState, endOfPlayScores)
  }

  def summary(endOfPlayScores: List[Int]): GameSummary =
    GameSummary(stopInfo, endOfPlayScores, scores)

  def addPlay(playerType: PlayerType, playPieces: List[PlayPiece]): Try[(GameState, List[Piece])] = {
    for {
      _ <- validatePlay(playerType, playPieces)
      movedGridPieces = playPieces filter { _.moved } map { _.gridPiece }
      score = computePlayScore(playPieces)
      added <- addGoodPlay(playerType, movedGridPieces, score)
    } yield added
  }

  def tray(playerType: PlayerType): Tray = trays(playerIndex(playerType))

  def computePlayScore(playPieces: List[PlayPiece]): Int = {
    val playHelper = new CrossWordFinder(board)
    game.scorer.scorePlay(playHelper, playPieces)
  }

  private def addGoodPlay(playerType: PlayerType, gridPieces: List[GridPiece], score: Int): Try[(GameState, List[Piece])] = {
    val newBoard = board.addPieces(gridPieces)
    val usedPieces = gridPieces map { _.value }
    val succPasses = if (score > 0) 0 else numSuccessivePasses + 1
    val ind = playerIndex(playerType)
    for {
      (nextGen, newPieces) <- tileSack.takeAvailableTiles(usedPieces.length)
      newTrays = trays.updated(ind, trays(ind).replacePieces(usedPieces, newPieces))
      newScores = scores.updated(ind, scores(ind) + score)
      nextType = nextPlayerType(playerType)
      newState = GameState(game, newBoard, newTrays, nextGen, playNumber + 1, nextType, score, succPasses, newScores)
    } yield ((newState, newPieces))
  }

  def swapPiece(piece: Piece, playerType: PlayerType): Try[(GameState, Piece)] = {
    val succPasses = numSuccessivePasses + 1
    // Cannot swap if no more pieces in the sack, so for now just return the same piece.
    // This is our way of doing a pass for now.
    if (tileSack.isEmpty) {
      val newState = this.copy(numSuccessivePasses = succPasses)
      return Success((newState, piece))
    }

    val trayIndex = PlayerType.playerIndex(playerType)
    val tray = trays(trayIndex)
    for {
      tray1 <- tray.removePiece(piece)
      (tileSack1, newPiece) <- tileSack.swapOne(piece)
      tray2 <- tray1.addPiece(newPiece)
      trays2 = trays.updated(playerIndex(playerType), tray2)
      newState = this.copy(trays = trays2, tileSack = tileSack1, numSuccessivePasses = succPasses)
    } yield (newState, newPiece)
  }

  /**
    * Check that cross words generated by this play are valid words in the dictionary.
    */
  def checkCrossWords(playPieces: List[PlayPiece], theDictionary: WordDictionary): Try[Unit] = {
    val theBoard = board
    val theTray = trays(playerIndex(UserPlayer))
    Try {
      val playStrip = board.stripOfPlay(playPieces)
      val stripMatcher = new StripMatcher {
        override def dictionary = theDictionary
        override def board = theBoard
        override def tray = theTray
      }
      val word = PlayPieceObj.playPiecesToWord(playPieces)
      val crosswords = stripMatcher.crossings(playStrip, word)
      val invalidCrosswords = crosswords.filter { w => !(theDictionary hasWord w) }
      if (!invalidCrosswords.isEmpty)
        throw new InvalidCrosswordsException(game.languageCode, invalidCrosswords)
    }
  }

  private def validatePlay(playerType: PlayerType, playPieces: List[PlayPiece]): Try[Unit] = {
    if (playerType == MachinePlayer)
      return Success(())

    for {
      _ <- checkPlayLineInBounds(playPieces)
      _ <- checkFirstPlayCentered(playPieces)
      _ <- checkPlayAnchored(playPieces)
      _ <- checkContiguousPlay(playPieces)
      _ <- checkMoveDestinationsEmpty(playPieces)
      _ <- checkUnmovedPlayPositions(playPieces)
      _ <- checkMoveTrayPieces(playPieces)
    } yield ()
  }

  // TODO. Implement all play validation checks.
  // Most of the validations are also done in the associated web ui.
  // To allow unrelated client code to use the API, however, these checks
  // need to be implemented.

  def inBounds(coordinate: Int): Boolean =
    coordinate >= 0 && coordinate < game.dimension

  def inBounds(point: Point): Boolean = {
    inBounds(point.row) && inBounds(point.col)
  }
  /**
    * Check that play locations are within the board's boundaries.
    */
  private def checkPlayLineInBounds(playPieces: List[PlayPiece]): Try[Unit] = Try {
    val points = playPieces.map {_.point}
    if (!points.forall(inBounds(_)))
      throw MalformedPlayException("play points out of bounds")
  }

  /**
    * Check that the first play includes the center point.
    */
  private def checkFirstPlayCentered(playPieces: List[PlayPiece]): Try[Unit] = Success(())

  /**
    * Check that the play is anchored - except for the first play.
    */
  private def checkPlayAnchored(playPieces: List[PlayPiece]): Try[Unit] = Success(())

  /**
    * Check that play for for a contiguous strip on the board.
    */
  private def checkContiguousPlay(playPieces: List[PlayPiece]): Try[Unit] = Try {
    val points = playPieces.map {_.point}
    if (points.length != points.distinct.length)
      throw MalformedPlayException("duplicate play points")

    val rows = points.map { _.row }
    val cols = points.map { _.col }

    // TODO. Move to util.
    def same[A](values: List[A]): Boolean =
      if (values.length < 2) true else values.drop(1).forall(_ == values.head)
    if (!same(rows) && !same(cols))
      throw MalformedPlayException("non-contiguous play points")
  }

  /**
    * Check that the destinations of the moved play pieces are empty.
    */
  private def checkMoveDestinationsEmpty(playPieces: List[PlayPiece]): Try[Unit] = Success(())

  /**
    * Check that the play pieces that are not moved and are supposed to exist on the board
    * are in fact there and contain the pieces indicated in the play.
    */
  private def checkUnmovedPlayPositions(playPieces: List[PlayPiece]): Try[Unit] = Success(())

  /**
    * Check that the moved pieces in this play are in fact user tray pieces.
    */
  private def checkMoveTrayPieces(playPieces: List[PlayPiece]): Try[Unit] = Success(())

  def sanityCheck: Try[Unit] = Try {
    val boardPieces = board.gridPieces.map { _.piece }
    val userTrayPieces = trays(playerIndex(PlayerType.UserPlayer)).pieces
    val machineTrayPieces = trays(playerIndex(PlayerType.MachinePlayer)).pieces

    val boardPieceIds = boardPieces.map { _.id }
    val userPieceIds = userTrayPieces.map { _.id }
    val machinePieceIds = machineTrayPieces.map { _.id }

    val allIds = boardPieceIds ++ userPieceIds ++ machinePieceIds
    val dups = allIds diff allIds.distinct
    if (dups.nonEmpty) {
      val message = s"duplicate ids in game state: ${dups}"
      logger.error(message)
      throw new IllegalStateException(message)
    }
  }
}

object GameState {

  def MaxSuccessivePasses = 6

  def mkGameState(game: Game, gridPieces: List[GridPiece],
    initUserPieces: List[Piece], initMachinePieces: List[Piece]): Try[GameState] = {

    val board = Board(game.dimension, gridPieces)
    // val pieceGenerator = TileSack(game.pieceGeneratorType)

    val pieceGenerator = game.pieceGeneratorType match {
      case PieceGeneratorType.Random => RandomTileSack(game.dimension)
      case PieceGeneratorType.Cyclic => CyclicTileSack()
    }

    val lastPlayScore = 0

    for {
      (userTray, pieceGen1) <- mkTray(game.trayCapacity, initUserPieces, pieceGenerator)
      (machineTray, pieceGen2) <- mkTray(game.trayCapacity, initMachinePieces, pieceGen1)
    }
      yield GameState(game, board, List(userTray, machineTray), pieceGen2, 0, UserPlayer, lastPlayScore, 0, List(0, 0))
  }

  def mkTray(capacity: Int, initPieces: List[Piece], pieceGen: TileSack): Try[(Tray, TileSack)] = {
    if (initPieces.length >= capacity)
      return Success((Tray(capacity, initPieces.take(capacity).toVector), pieceGen))

    for {
      (nextGen, restPieces) <- pieceGen.takeAvailableTiles(capacity - initPieces.length)
      pieces = initPieces ++ restPieces
    } yield (Tray(capacity, pieces.toVector), nextGen)
  }
}
