//package com.bolour.util.scala.common
//
//import com.bolour.util.scala.server.BasicServerUtil
//import org.scalatest.{FlatSpec, Matchers}
//
//class ReadBytesSpec extends FlatSpec with Matchers {
//
//  val maskedWordsPath = "dict/en-masked-words.txt"
//
//  "masked words file" should "be read quickly as bytes" in {
//    val begin = System.currentTimeMillis()
//    val bytes = BasicServerUtil.readFileAsBytes(maskedWordsPath).get
//    println(bytes(100000))
//    val string = new String(bytes)
//    println(string.charAt(100000))
//    val lines = string.split("\\r?\\n")
//    println(lines(5000))
//    val set = lines.toSet
//    println(set.contains("Z O"))
//    val end = System.currentTimeMillis()
//    val time = (end - begin)/1000
//    println(s"time: ${time} seconds")
//
//  }
//}
