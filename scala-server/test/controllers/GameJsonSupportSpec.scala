/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package controllers

import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory
import play.api.libs.json.{JsError, JsString, JsSuccess, Json}
import com.bolour.boardgame.scala.common.domain.PieceProviderType.PieceProviderType
import controllers.GameApiJsonSupport._

class GameJsonSupportSpec extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)

  "piece provider type info" should "get values" in {
    val jsonString = "Cyclic"
    val jsValue = JsString(jsonString)
    val result = Json.fromJson[PieceProviderType](jsValue)
    result match {
      case JsSuccess(genType, _) => println(s"${genType}")
      case JsError(ex) =>
        logger.error(s"${ex}")
        throw new Exception(s"${ex}")
    }
    println(s"${result}")
  }
}
