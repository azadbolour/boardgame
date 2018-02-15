package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{GridPiece, Piece, Point}
import com.bolour.boardgame.scala.server.util.WordUtil
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class HopelessBlanksSpec extends FlatSpec with Matchers { self =>
  val logger = LoggerFactory.getLogger(this.getClass)

  val MaxMaskedLetters = 2

  val words = List("AND", "CAN", "DO", "AT")
  val dictionary = WordDictionary(WordUtil.english, words, MaxMaskedLetters)
  val dimension = 3
  val emptyBoard = Board(dimension)
  val tray = Tray(3, Vector()) // Don't need the tray contents, just capacity.

  val gridPieces = List(
    GridPiece(Piece('A', "0"), Point(1, 0)),
    GridPiece(Piece('N', "1"), Point(1, 1)),
    GridPiece(Piece('D', "2"), Point(1, 2)),
    GridPiece(Piece('T', "3"), Point(2, 0))
  )

  val board = emptyBoard.addPieces(gridPieces)

  val stripMatcher = new StripMatcher {
    override def tray = self.tray
    override def dictionary = self.dictionary
    override def board = self.board
  }

  "strip matcher" should "find hopeless blanks" in {
    val hopelessBlankPoints = stripMatcher.hopelessBlankPoints
    println(hopelessBlankPoints)
  }

}
