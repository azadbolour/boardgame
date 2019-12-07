/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

import com.bolour.util.scala.common.CommonUtil.{ID, Email}

/**
  * Data transfer object for a user. See Player domain class.
  */
case class PlayerDto(id: ID, userId: String, name: String, email: Email)
