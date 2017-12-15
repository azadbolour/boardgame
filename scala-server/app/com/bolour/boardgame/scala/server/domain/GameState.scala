/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.PlayerType.{playerIndex, _}
import com.bolour.boardgame.scala.server.domain.GameExceptions.InvalidCrosswordsException
import com.bolour.boardgame.scala.server.util.WordUtil

import scala.util.{Failure, Success, Try}

case class GameState(
  game: Game,
  board: Board,
  trays: List[Tray],
  pieceGenerator: TileSack,
  playNumber: Int,
  playTurn: PlayerType,
  scores: List[Int]
) {


  def addPlay(playerType: PlayerType, playPieces: List[PlayPiece]): Try[(GameState, List[Piece])] = {
    for {
      _ <- validatePlay(playPieces)
      movedGridPieces = playPieces filter { _.moved } map { _.gridPiece }
      score = computePlayScore(playPieces)
      added <- addGoodPlay(playerType, movedGridPieces, score)
    } yield added
  }

  def tray(playerType: PlayerType): Tray = trays(playerIndex(playerType))

  def computePlayScore(playPieces: List[PlayPiece]): Int = {
    val playHelper = new PlayHelper(board)
    game.scorer.scorePlay(playHelper, playPieces)
  }

  private def addGoodPlay(playerType: PlayerType, gridPieces: List[GridPiece], score: Int): Try[(GameState, List[Piece])] = {
    val newBoard = board.addPieces(gridPieces)
    val usedPieces = gridPieces map { _.value }
    val ind = playerIndex(playerType)
    for {
      (nextGen, newPieces) <- pieceGenerator.taken(usedPieces.length)
      newTrays = trays.updated(ind, trays(ind).replacePieces(usedPieces, newPieces))
      newScores = scores.updated(ind, scores(ind) + score)
      nextType = nextPlayerType(playerType)
      newState = GameState(game, newBoard, newTrays, nextGen, playNumber + 1, nextType, newScores)
    } yield ((newState, newPieces))
  }

  def swapPiece(piece: Piece, playerType: PlayerType): Try[(GameState, Piece)] = {
    val trayIndex = PlayerType.playerIndex(playerType)
    val tray = trays(trayIndex)
    for {
      tray1 <- tray.removePiece(piece)
      (nextGen, newPiece) <- pieceGenerator.swapOne(piece)
      tray2 <- tray1.addPiece(newPiece)
      trays2 = trays.updated(playerIndex(MachinePlayer), tray2)
      // newState <- this.copy(trays = trays2, pieceGenerator = nextGen)
      newState = this.copy(trays = trays2, pieceGenerator = nextGen)
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

  // TODO. Implement validation by chaining all teh specific validations.
  private def validatePlay(playPieces: List[PlayPiece]): Try[Unit] = Success(())

  // TODO. Validate the play.
  // Most of the validations are also done in the associated web ui.
  // To allow unrelated client code to use the API, however, these checks
  // need to be implemented.

  /**
    * Check that play locations are within the board's boundaries.
    */
  private def checkPlayLineInBounds(playPieces: List[PlayPiece]): Try[Unit] = Success(())

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
  private def checkContiguousPlay(playPieces: List[PlayPiece]): Try[Unit] = Success(())

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
}

object GameState {
  def mkGameState(game: Game, gridPieces: List[GridPiece],
    initUserPieces: List[Piece], initMachinePieces: List[Piece]): Try[GameState] = {

    val board = Board(game.dimension, gridPieces)
    val pieceGenerator = TileSack(game.pieceGeneratorType)

    for {
      (userTray, pieceGen1) <- mkTray(game.trayCapacity, initUserPieces, pieceGenerator)
      (machineTray, pieceGen2) <- mkTray(game.trayCapacity, initMachinePieces, pieceGen1)
    }
      yield GameState(game, board, List(userTray, machineTray), pieceGen2, 0, UserPlayer, List(0, 0))
  }

  def mkTray(capacity: Int, initPieces: List[Piece], pieceGen: TileSack): Try[(Tray, TileSack)] = {
    if (initPieces.length >= capacity)
      return Success((Tray(capacity, initPieces.take(capacity).toVector), pieceGen))

    for {
      (nextGen, restPieces) <- pieceGen.taken(capacity - initPieces.length)
      pieces = initPieces ++ restPieces
    } yield (Tray(capacity, pieces.toVector), nextGen)
  }
}
