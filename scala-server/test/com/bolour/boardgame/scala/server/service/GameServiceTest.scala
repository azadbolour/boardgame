package com.bolour.boardgame.scala.server.service

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.server.domain.Player
import com.bolour.boardgame.scala.server.util.WordUtil
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
  val genType = PieceGeneratorType.Random
  val gameParams = GameParams(dimension, trayCapacity, tinyLang, name, genType)

  val service = new GameServiceImpl(ConfigFactory.load())
  service.migrate()
  service.addPlayer(Player(name))

  def gp(letter: Char, row: Int, col: Int) = GridPiece(Piece(letter), Point(row, col))

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
    for {
      state <- service.startGame(gameParams, gridPieces, initUserPieces, List())
      (score, replacementPieces) <- service.commitPlay(state.game.id, playPieces)
    } yield (state, score, replacementPieces)
  }

  "game service" should "accept valid crosswords" in {
    // Allow only O to be used.
    val uPieces = List(Piece('O'), Piece('O'))
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
    val uPieces = List(Piece('O'), Piece('O'))
    val playPieces = List(
      PlayPiece(top.piece, top.point, false),
      // Add O to the top right getting word SO and crossword OT (which is invalid).
      PlayPiece(uPieces(0), Point(center - 1, center + 1), true)
    )
    val tried = startGameAndCommitPlay(uPieces, playPieces)
    tried.isFailure shouldBe true
  }

}