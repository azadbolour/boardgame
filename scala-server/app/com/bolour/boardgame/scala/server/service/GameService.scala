/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.service

import com.bolour.util.scala.common.CommonUtil.ID
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.Scorer.Score
import com.bolour.boardgame.scala.server.domain.{GameBase, Game, Player}
import com.bolour.plane.scala.domain.Point

import scala.util.Try

/**
  * Trait representing the service layer of the application.
  *
  * All methods return Try of the data needed for the happy path to represent
  * possible errors. We won't repeat this for every method.
  */
trait GameService {

  // TODO. Add parameter validation is common to all implementations.

  /**
    * Migrate the persistent data.
    */
  def migrate(): Try[Unit]

  /**
    * Clear ut the persistent data (for testing).
    */
  def reset(): Try[Unit]

  /**
    * Add a new player.
    */
  def addPlayer(player: Player): Try[Unit]

  /**
    * Start a new game.
    *
    * @param gameParams Specification of the new game.
    * @param pointValues The values assigned to each point of the board for scoring.
    *                    Scores depend on point values captured by a played word.
    *                    Point values are always provided by clients.
    * @return The created game.
    */
  def startGame(
    gameParams: GameParams,
    initPieces: InitPieces,
    pointValues: List[List[Int]]
  ): Try[Game]

  /**
    * Commit a user play.
    *
    * @param gameId Unique id of the game.
    * @param playPieces The specification of the played word: a sequence of play pieces,
    *                   one for each letter of the word, designating the letter, its location,
    *                   and whether it was moved from the tray in this play.
    * @return Tuple (mini state, replacement pieces, dead locations).
    *         The mini state is minimal information about the updated game needed by clients.
    *         Replacement pieces fill in for the pieces used in the play.
    *         Dead locations are board locations that were detected as impossible to fill
    *         after this play.
    */
  def commitPlay(gameId: ID, playPieces: List[PlayPiece]): Try[(GameMiniState, List[Piece], List[Point])]

  /**
    * Make a machine play.
    *
    * See commitPlay for parameters and return.
    */
  def machinePlay(gameId: ID): Try[(GameMiniState, List[PlayPiece], List[Point])]

  /**
    * Swap a user piece.
    *
    * Note. Swapping of machine piece is an implementation detail of machinePlay.
    *
    * @param gameId Unique id of the game.
    * @param piece Piece being swapped.
    * @return Minimal state of the game after the swap and the new piece.
    */
  def swapPiece(gameId: ID, piece: Piece): Try[(GameMiniState, Piece)]

  /**
    * End the game.
    *
    * @param gameId Unique id of the game.
    * @return Summary of the game.
    */
  def endGame(gameId: ID): Try[GameSummary]

  /**
    * Find a game.
    */
  def findGameById(gameId: ID): Try[Option[Game]]

  /**
    * Harvest long-running games - considering them and abandoned.
    */
  def timeoutLongRunningGames(): Try[Unit]

}

object GameService {
  val serviceConfigPrefix = "service"
  def confPath(pathInService: String) =  s"${serviceConfigPrefix}.${pathInService}"

  val maxActiveGamesConfigPath = confPath("maxActiveGames")
  val maxGameMinutesConfigPath = confPath("maxGameMinutes")
  val languageCodesConfigPath = confPath("languageCodes")

}
