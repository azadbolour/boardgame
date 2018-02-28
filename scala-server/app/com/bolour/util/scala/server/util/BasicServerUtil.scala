/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.util.scala.server.util

import java.util.UUID

import com.bolour.boardgame.scala.server.domain.WordDictionary.classLoader
import com.bolour.util.scala.common.util.CommonUtil.javaListToScala
import com.typesafe.config.ConfigFactory

import scala.io.{BufferedSource, Source}
import scala.util.Try

object BasicServerUtil {
  def stringId() = UUID.randomUUID().toString

  def readConfigStringList(path: String): Try[List[String]] = {
    Try {
      val config = ConfigFactory.load()
      val javaList = config.getStringList(path)
      javaListToScala(javaList)
    }
  }

  def mkFileSource(path: String): Try[BufferedSource] =
    Try { Source.fromFile(path) }

  def mkResourceSource(path: String): Try[BufferedSource] =
    Try { Source.fromResource(path, classLoader)}

  type GiverTaker[A] = (Vector[A], Vector[A])

  def giveRandomElement[A](giverTaker: GiverTaker[A]): GiverTaker[A] = {
    val (giver, taker) = giverTaker
    val index = (Math.random() * giver.length).toInt
    val element = giver(index)
    val giver1 = giver.patch(index, Nil, 1)
    (giver1, taker :+ element)
  }

  def giveRandomElements[A](giverTaker: GiverTaker[A], n : Int): GiverTaker[A] = {
    if (n == 0) return giverTaker
    val giverTaker1 = giveRandomElement(giverTaker)
    giveRandomElements(giverTaker1, n - 1)
  }

}
