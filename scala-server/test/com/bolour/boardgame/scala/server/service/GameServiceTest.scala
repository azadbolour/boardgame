package com.bolour.boardgame.scala.server.service

import com.bolour.util.scala.server.BasicServerUtil.stringId
import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.Player
import com.bolour.plane.scala.domain.Point
import com.typesafe.config.ConfigFactory
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
  service.addPlayer(Player(name))

  def gp(letter: Char, row: Int, col: Int) = GridPiece(Piece(letter, stringId()), Point(row, col))

  val top = gp('S', center - 1, center)
  val bottom = gp('T', center + 1, center)
  // _ S _
  // B E T
  // _ T _
  val gridPieces = List(
    gp('B', center, center),
    gp('E', center, center + 1),
    gp('T', center, center + 2),
    top,
    bottom,
  )

  def startGameAndCommitPlay(initUserPieces: List[Piece], playPieces: List[PlayPiece]) = {
    val pointValues = List.fill(dimension, dimension)(1)
    for {
      state <- service.startGame(gameParams, gridPieces, initUserPieces, List(), pointValues)
      (score, replacementPieces, deadPoints) <- service.commitPlay(state.game.id, playPieces)
    } yield (state, score, replacementPieces)
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
      (state, _, replacementPieces) <- startGameAndCommitPlay(uPieces, playPieces)
      _ = replacementPieces.length shouldBe 1
    } yield state
  }

  "game service" should "reject invalid crosswords" in {
    // Allow only Q to be used.
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
