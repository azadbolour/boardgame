package com.bolour.boardgame.scala.server.service

import play.api.inject.{SimpleModule, _}

class GameHarvesterModule extends SimpleModule(bind[GameHarvester].toSelf.eagerly())

