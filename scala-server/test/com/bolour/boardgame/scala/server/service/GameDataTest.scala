/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.service

import spray.json._
import com.bolour.boardgame.scala.common.domain.PlayerType.UserPlayer
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.Player
import com.bolour.plane.scala.domain.Point
import com.bolour.util.scala.server.BasicServerUtil.stringId
import com.typesafe.config.ConfigFactory
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory
import com.bolour.boardgame.scala.server.domain.json.CaseClassFormats._

class GameDataTest extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)

  val dimension = 5
  val trayCapacity = 2
  val center = dimension / 2
  val tinyLang = "tiny"
  val name = "John"
  val genType = PieceProviderType.Random
  val gameParams = GameParams(dimension, trayCapacity, tinyLang, name, genType)

  val service = new GameServiceImpl(ConfigFactory.load())
  service.migrate()
  service.addPlayer(Player(stringId, name))

  def gp(letter: Char, row: Int, col: Int) = PiecePoint(Piece(letter, stringId()), Point(row, col))

  val top = gp('S', center - 1, center)
  val bottom = gp('T', center + 1, center)
  // _ S _
  // B E T
  // _ T _
  val piecePoints = List(
    gp('B', center, center - 1),
    gp('E', center, center),
    gp('T', center, center + 1),
    top,
    bottom,
  )

  def startGameAndCommitPlay(initUserPieces: List[Piece], playPieces: List[PlayPiece]) = {
    val pointValues = List.fill(dimension, dimension)(1)
    for {
      game <- service.startGame(gameParams, piecePoints, initUserPieces, List(), pointValues)
      (playedGame, _, _) <- game.addWordPlay(UserPlayer, playPieces)
    } yield playedGame
  }

  "game transitions" should "should be convertible to json" in {
    // Allow only O to be used.
    val uPieces = List(Piece('O', stringId()), Piece('O', stringId()))
    val playPieces = List(
      PlayPiece(bottom.piece, bottom.point, false),
      PlayPiece(uPieces(0), Point(center + 1, center + 1), true)
    )
    val triedGame = for {
      game <- startGameAndCommitPlay(uPieces, playPieces)
    } yield game

    val game = triedGame.get
    game.plays.size shouldEqual 1

    val gameTransitions = game.transitions

    val json = gameTransitions.toJson
    val string = json.prettyPrint

    logger.info(s"${string}")

    val jsonAst = string.parseJson
    val decodedTransitions: GameData = jsonAst.convertTo[GameData]

    decodedTransitions shouldEqual gameTransitions
  }


}
