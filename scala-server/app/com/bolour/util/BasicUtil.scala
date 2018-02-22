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

  def inverseMultiValuedMapping[A, B](f: A => List[B])(as: List[A]): Map[B, List[A]] = {
    def pairMaker(a: A): List[(A, B)] = f(a) map {b => (a, b)}
    val pairs = as flatMap pairMaker
    pairs.groupBy(_._2).mapValues(_ map {case (a, b) => a})
  }

}
