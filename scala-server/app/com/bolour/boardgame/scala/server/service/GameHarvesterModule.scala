/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.scala.server.service

import play.api.inject.{SimpleModule, _}

class GameHarvesterModule extends SimpleModule(bind[GameHarvester].toSelf.eagerly())

