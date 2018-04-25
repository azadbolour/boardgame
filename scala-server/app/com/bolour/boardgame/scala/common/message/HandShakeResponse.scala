/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.message

/**
  * API response for the initial handshake.
  *
  * @param serverType - Scala, ...
  * @param apiVersion
  */
case class HandShakeResponse(
  serverType: String,
  apiVersion: String
)
