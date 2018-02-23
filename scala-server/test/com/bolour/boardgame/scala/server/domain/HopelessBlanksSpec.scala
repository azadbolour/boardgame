package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{GridPiece, Piece, Point}
import com.bolour.boardgame.scala.server.util.WordUtil
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class HopelessBlanksSpec extends FlatSpec with Matchers { self =>
  val logger = LoggerFactory.getLogger(this.getClass)

  val MaxMaskedLetters = 2
  val trayCapacity = 3

  val words = List("AND", "TAN")
  val dictionary = WordDictionary(WordUtil.english, words, MaxMaskedLetters)
  val dimension = 3
  val emptyBoard = Board(dimension)
  val tray = Tray(trayCapacity, Vector()) // Don't need the tray contents, just capacity.

  val gridPieces = List(
    GridPiece(Piece('A', "0"), Point(2, 0)),
    GridPiece(Piece('N', "1"), Point(2, 1)),
    GridPiece(Piece('D', "2"), Point(2, 2)),
    GridPiece(Piece('T', "3"), Point(0, 1)),
    GridPiece(Piece('A', "4"), Point(1, 1))
  )

  val board = emptyBoard.setN(gridPieces)

  "strip matcher" should "find hopeless blanks" in {
    val hopelessBlankPoints = StripMatcher.hopelessBlankPoints(board, dictionary, trayCapacity)
    println(hopelessBlankPoints)
    hopelessBlankPoints.size should be > 0
  }

}
