/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
import com.google.inject.{AbstractModule, Provides}
import java.time.Clock

import com.bolour.boardgame.scala.server.service.{GameService, GameServiceImpl}
import com.typesafe.config.ConfigFactory
import play.api.{Configuration, Environment}

// import services.{ApplicationTimer, AtomicCounter, Counter}

/**
  * This class is a Guice module that tells Guice how to bind several
  * different types. This Guice module is created when the Play
  * application starts.

  * Play will automatically use any class called `Module` that is in
  * the root package. You can create modules in other locations by
  * adding `play.modules.enabled` settings to the `application.conf`
  * configuration file.
  * The environment and configuration are automatically provided by
  * the play framework. Configuration is a wrapper on Conf from application.conf.
  * TODO. Study environment functions.
  */
class Module(environment: Environment, configuration: Configuration) extends AbstractModule {

  val conf = configuration.underlying

  override def configure() = {
    // Use the system clock as the default implementation of Clock
    bind(classOf[Clock]).toInstance(Clock.systemDefaultZone)
    // Ask Guice to create an instance of ApplicationTimer when the
    // application starts.
    // bind(classOf[ApplicationTimer]).asEagerSingleton()
    // Set AtomicCounter as the implementation for Counter.
    // bind(classOf[Counter]).to(classOf[AtomicCounter])
    // Keep the service layer independent of the web framework.
    // Configuration is a Play concern. Config is generic scala.
    // TODO. Reinstate once migration (see provider below) is done properly.
    // bind(classOf[GameService]).toInstance(new GameServiceImpl(conf))
  }

  @Provides
  def provideGameService: GameService = {
    val service = new GameServiceImpl(ConfigFactory.load())
    service.migrate() // TODO. This is a hack to get going. How to do play-idiomatic migration. See play-slick.
    service
  }

}
