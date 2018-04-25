/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.service

import javax.inject.{Inject}

import akka.actor.{ActorSystem}
import org.slf4j.LoggerFactory

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

/**
  * Periodically harvests long-running games considering them as abandoned.
  *
  * @param actorSystem Needed for scheduling harvesting actor.
  * @param service The game service.
  * @param executionContext Context in which to run the harvester.
  */
class GameHarvester @Inject() (actorSystem: ActorSystem, service: GameService)(implicit executionContext: ExecutionContext) {

  actorSystem.scheduler.schedule(initialDelay = 10.minutes, interval = 10.minutes) {
    service.timeoutLongRunningGames()
  }

}
