/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.util.scala.server

import java.io.{File, FileInputStream}
import java.util.UUID

import com.bolour.util.scala.common.CommonUtil.javaListToScala
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

  def mkResourceSource(path: String, classLoader: ClassLoader): Try[BufferedSource] =
    Try { Source.fromResource(path, classLoader)}

  def readFileAsBytes(path: String): Try[Array[Byte]] = {
    var buffer: Array[Byte] = new Array[Byte](1000)
    Try {
      val file = new File(path)
      val size = file.length().toInt
      val bytes: Array[Byte] = new Array[Byte](size)
      var i = 0
      var n = 0
      val input = new FileInputStream(path)
      while (n != -1) {
        n = input.read(buffer);
        if (n != -1) {
          Array.copy(buffer, 0, bytes, i, n)
          i = i + n
        }
      }
      bytes
    }
  }

}
