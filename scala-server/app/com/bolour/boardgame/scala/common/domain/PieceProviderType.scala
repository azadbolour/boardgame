/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

object PieceProviderType {

  val RandomAsString = "Random"
  val CyclicAsString = "Cyclic"

  sealed abstract class PieceProviderType
  object Random extends PieceProviderType {
    override def toString = RandomAsString
  }
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

//object PieceProviderType extends Enumeration {
//  type PieceProviderType = Value
//  val Random, Cyclic = Value
//}
