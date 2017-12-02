/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.util

import java.util.UUID

import com.bolour.boardgame.scala.server.domain.WordDictionary.classLoader
import com.typesafe.config.ConfigFactory

import scala.io.{BufferedSource, Source}
import scala.util.Try

object BasicUtil {
  type ID = String
  def stringId() = UUID.randomUUID().toString

  def javaListToScala[T](source: java.util.List[T]): List[T] = {
    // TODO. Scala syntax for inlining the next two lines as a parameter to fill??
    val it = source.iterator()
    def nextElement: T = it.next()
    source match {
      case null => List()
      case _ => List.fill(source.size()) { nextElement }
    }
  }

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


}
