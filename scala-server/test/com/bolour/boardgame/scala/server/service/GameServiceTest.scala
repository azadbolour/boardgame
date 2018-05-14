/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.service

import com.bolour.util.scala.server.BasicServerUtil.stringId
import com.bolour.boardgame.scala.server.domain.Player
import com.typesafe.config.ConfigFactory
import com.bolour.boardgame.scala.common.domain._
import com.bolour.plane.scala.domain.Point
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class GameServiceTest extends FlatSpec with Matchers {

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

  def piecePoint(letter: Char, row: Int, col: Int) = PiecePoint(Piece(letter, stringId()), Point(row, col))

  val top = piecePoint('S', center - 1, center)
  val bottom = piecePoint('T', center + 1, center)
  // _ S _
  // B E T
  // _ T _
  val piecePoints = List(
    piecePoint('B', center, center - 1),
    piecePoint('E', center, center),
    piecePoint('T', center, center + 1),
    top,
    bottom,
  )

  def startGameAndCommitPlay(initUserPieces: List[Piece], playPieces: List[PlayPiece]) = {
    val initPieces = InitPieces(piecePoints, initUserPieces, List())
    val pointValues = List.fill(dimension, dimension)(1)
    for {
      game <- service.startGame(gameParams, initPieces, pointValues)
      (score, replacementPieces, deadPoints) <- service.commitPlay(game.gameBase.gameId, playPieces)
    } yield (game, score, replacementPieces)
  }

  "game service" should "accept valid crosswords" in {
    // Allow only O to be used.
    val uPieces = List(Piece('O', stringId()), Piece('O', stringId()))
    val playPieces = List(
      PlayPiece(bottom.piece, bottom.point, false),
      // Add O to the bottom right getting word TO and crossword TO (which is valid).
      PlayPiece(uPieces(0), Point(center + 1, center + 1), true)
    )
    for {
      (game, _, replacementPieces) <- startGameAndCommitPlay(uPieces, playPieces)
      _ = replacementPieces.length shouldBe 1
    } yield game
  }

  "game service" should "reject invalid crosswords" in {
    // Allow only O to be used.
    val uPieces = List(Piece('O', stringId()), Piece('O', stringId()))
    val playPieces = List(
      PlayPiece(top.piece, top.point, false),
      // Add O to the top right getting word SO and crossword OT (which is invalid).
      PlayPiece(uPieces(0), Point(center - 1, center + 1), true)
    )
    val tried = startGameAndCommitPlay(uPieces, playPieces)
    tried.isFailure shouldBe true
  }

}
