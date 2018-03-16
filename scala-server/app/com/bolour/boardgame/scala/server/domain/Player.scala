/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.util.scala.common.CommonUtil.{ID}
import com.bolour.util.scala.server.BasicServerUtil.{stringId}

case class Player(id: ID, name: String)

object Player {
  def apply(name: String): Player = Player(stringId, name)
}
