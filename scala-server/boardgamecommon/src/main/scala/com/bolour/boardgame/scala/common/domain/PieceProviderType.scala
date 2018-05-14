/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

object PieceProviderType {

  val RandomAsString = "Random"
  val CyclicAsString = "Cyclic"

  /**
    * Type of factory used to generate new pieces for use
    * in the game.
    */
  sealed abstract class PieceProviderType

  /**
    * Factory type to generate random pieces. The default.
    */
  object Random extends PieceProviderType {
    override def toString = RandomAsString
  }

  /**
    * Factory type to generate pieces by cycling through the alphabet.
    * Used for deterministic testing.
    */
  object Cyclic extends PieceProviderType {
    override def toString = CyclicAsString
  }

  def fromString(asString: String): PieceProviderType = {
    asString match {
      case RandomAsString => PieceProviderType.Random
      case CyclicAsString => PieceProviderType.Cyclic
      case _ => throw new RuntimeException(s"unrecognized piece provider type: ${asString}")
    }
  }
}

