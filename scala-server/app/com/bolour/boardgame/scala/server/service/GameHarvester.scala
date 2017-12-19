package com.bolour.boardgame.scala.server.service

import javax.inject.{Inject, Named}

import akka.actor.{ActorSystem}
import org.slf4j.LoggerFactory

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

class GameHarvester @Inject() (actorSystem: ActorSystem, service: GameService)(implicit executionContext: ExecutionContext) {

  val logger = LoggerFactory.getLogger(this.getClass)

  logger.info("entered GameHarvester")

  // actorSystem.scheduler.schedule(initialDelay = 10.seconds, interval = 1.minute) {
  actorSystem.scheduler.schedule(initialDelay = 5.seconds, interval = 1.minute) {
    service.timeoutLongRunningGames()
  }

}
