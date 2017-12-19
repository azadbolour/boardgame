package com.bolour.boardgame.scala.server.service

import javax.inject.{Inject}

import akka.actor.{ActorSystem}
import org.slf4j.LoggerFactory

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

class GameHarvester @Inject() (actorSystem: ActorSystem, service: GameService)(implicit executionContext: ExecutionContext) {

  val logger = LoggerFactory.getLogger(this.getClass)

  actorSystem.scheduler.schedule(initialDelay = 10.minutes, interval = 10.minutes) {
    service.timeoutLongRunningGames()
  }

}
