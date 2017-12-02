/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
//package com.bolour.boardgame.scala.server
//
//import scala.io.StdIn
//import com.typesafe.config.{Config, ConfigException, ConfigFactory}
//import akka.actor.ActorSystem
//import akka.http.scaladsl.Http
//import akka.stream.ActorMaterializer
//import com.bolour.boardgame.scala.server.service.GameServiceImpl
//import com.bolour.boardgame.scala.server.web.GameEndPoint
//
//object GameServer {
//  def main(args: Array[String]) {
//
//    if (args.length > 1) {
//      println(s"Usage: GameServer [serverPort] - wrong number of arguments: ${args}")
//      System.exit(-1)
//    }
//
//    implicit val system = ActorSystem("my-system")
//    implicit val materializer = ActorMaterializer()
//    // needed for the future flatMap/onComplete in the end
//    implicit val executionContext = system.dispatcher
//
//    val config = ConfigFactory.load()
//    val service = new GameServiceImpl(config)
//    service.migrate().get
//    val gameEndPoint = GameEndPoint(service)
//    val gameRoute = gameEndPoint.gameRoute
//
//    val port = if (args.isEmpty) readConfigPort(config) else readPort(args(0))
//    if (port < 0) {
//      System.exit(-1)
//    }
//
//    val bindingFuture = Http().bindAndHandle(gameRoute, "localhost", port)
//    println(s"game server started at http://localhost:${port}/\nhit RETURN to stop")
//    StdIn.readLine() // let it run until user presses return
//    bindingFuture
//      .flatMap(_.unbind()) // trigger unbinding from the port
//      .onComplete(_ => system.terminate()) // and shutdown when done
//  }
//
//  val apiConfigPrefix = "api"
//  def apiConfigPath(path: String) = s"${apiConfigPrefix}.${path}"
//
//  val minPort = 1025
//  private def validPort(port: Int): Boolean = port >= minPort
//  private def portValidationMessage(port: Int) = s"invalid server port: ${port} - please use ports >= ${minPort}"
//
//  private def readConfigPort(conf: Config): Int = {
//    val portConfPath = apiConfigPath("serverPort")
//
//    try {
//      val port = conf.getInt(portConfPath)
//      if (!validPort(port))
//        println(portValidationMessage(port))
//      port
//    }
//    catch {
//      case mx: ConfigException.Missing =>
//        println(s"${portConfPath} is not configured")
//        -1
//      case wtx: ConfigException.WrongType =>
//        println(s"${portConfPath} is not readable: ${wtx.getMessage}")
//        -1
//    }
//  }
//
//  private def readPort(arg: String): Int = {
//    try {
//      arg.toInt
//    }
//    catch {
//      case ex: Exception =>
//        println(s"Usage: GameServer [serverPort] - unable to parse serverPort: ${arg} - ${ex.getMessage}")
//        -1
//    }
//  }
//}
