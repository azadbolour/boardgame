/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.typesafe.config.ConfigFactory
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory
import com.bolour.boardgame.scala.common.domain.{PiecePoint, Piece}
import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.language.scala.domain.WordDictionary
import com.bolour.plane.scala.domain.Point

class StripMatcherSpec extends FlatSpec with Matchers { self =>
  val logger = LoggerFactory.getLogger(this.getClass)

  val MaxMaskedLetters = 2

  // val config = ConfigFactory.load()
  val words = List("BAT", "BET", "EATEN")
  val maskedWords = WordDictionary.mkMaskedWords(words, MaxMaskedLetters)
  val dictionary = WordDictionary(WordUtil.english, words, maskedWords, MaxMaskedLetters)
  val dimension = 7
  val emptyBoard = Board(dimension)
  val pieces = Vector(
    Piece('B', "id1"),
    Piece('E', "id2"),
    Piece('T', "id3"),
  )
  val tray = Tray(7, pieces)
  val center: Int = dimension/2

  val gridPieces = List(PiecePoint(Piece('A', "idA"), Point(center, center)))

  val board = emptyBoard.setPiecePoints(gridPieces)

  val emptyStripMatcher = new StripMatcher {
    override def tray = self.tray
    override def dictionary = self.dictionary
    override def board = self.emptyBoard
  }

  val stripMatcher = new StripMatcher {
    override def tray = self.tray
    override def dictionary = self.dictionary
    override def board = self.board
  }

  "strip matcher" should "find all playable board strips" in {
    val valuation: Strip => Int = _.numBlanks
    val playableStrips = stripMatcher.groupPlayableStrips(valuation)
    val l = tray.pieces.length
    // assuming tray size <= center
    // for x to the left of center we can have 0, 1, 2 ... l - x to the right
    // except when x is 0 we need at least 1 to the right
    // hence (sum(1 .. l + 1) - 1) horizontal ones - double to get verticals as well
    val numPlayableStrips = (l + 1) * (l + 2) - 2
    logger.info(s"playable strips: ${playableStrips}")
    val num = playableStrips.toList.flatMap(_._2).flatMap(_._2).length
    num shouldEqual numPlayableStrips
  }

  "strip matcher" should "find a match" in {
    val playPieces = stripMatcher.bestMatch()
    logger.info(s"theMatch: ${playPieces}")
    playPieces should not be empty
  }

  "strip matcher" should "find a match on empty board" in {
    val playPieces = emptyStripMatcher.bestMatch()
    logger.info(s"theMatch: ${playPieces}")
    playPieces should not be empty
  }

}
