/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.language.scala.domain.WordDictionary
import com.bolour.boardgame.scala.common.domain.{Piece, PiecePoint}
import com.bolour.plane.scala.domain.Point
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class HopelessBlanksSpec extends FlatSpec with Matchers { self =>
  val logger = LoggerFactory.getLogger(this.getClass)

  val MaxMaskedLetters = 2
  val trayCapacity = 3

  val words = List("AND", "TAN")
  val maskedWords = WordDictionary.mkMaskedWordsCompact(words, MaxMaskedLetters)
  val dictionary = WordDictionary(WordUtil.english, words, maskedWords, MaxMaskedLetters)
  val dimension = 3
  val emptyBoard = Board(dimension)
  val tray = Tray(trayCapacity, Vector()) // Don't need the tray contents, just capacity.

  val piecePoints = List(
    PiecePoint(Piece('A', "0"), Point(2, 0)),
    PiecePoint(Piece('N', "1"), Point(2, 1)),
    PiecePoint(Piece('D', "2"), Point(2, 2)),
    PiecePoint(Piece('T', "3"), Point(0, 1)),
    PiecePoint(Piece('A', "4"), Point(1, 1))
  )

  val board = emptyBoard.setPiecePoints(piecePoints)

  "strip matcher" should "find hopeless blanks" in {
    val hopelessBlankPoints = StripMatcher.findBlackPoints(board, dictionary)
    println(hopelessBlankPoints)
    hopelessBlankPoints.size should be > 0
  }

}
