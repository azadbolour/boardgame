package com.bolour.boardgame.scala.server.domain.json

import org.slf4j.LoggerFactory
import spray.json.{DefaultJsonProtocol, JsString, JsValue, RootJsonFormat, deserializationError}
import com.bolour.boardgame.scala.server.domain.{PlayType, SwapPlayType, WordPlayType}
import com.bolour.boardgame.scala.server.domain.json.JsonUtil._

object PlayTypeJsonProtocol extends DefaultJsonProtocol {

  val logger = LoggerFactory.getLogger(this.getClass)

  // Use Pascal-case constants used in cases.
  val WordPlayTypeString = "WordPlayType"
  val SwapPlayTypeString = "SwapPlayType"

  implicit object PlayTypeFormat extends RootJsonFormat[PlayType] {
    override def write(playType: PlayType): JsValue = playType match {
      case WordPlayType => JsString(WordPlayTypeString)
      case SwapPlayType => JsString(SwapPlayTypeString)
    }

    override def read(json: JsValue): PlayType = {
      val playStringType = unwrapQuotedJsonString(json)
      playStringType match {
        case WordPlayTypeString => WordPlayType
        case SwapPlayTypeString => SwapPlayType
        case _ => deserializationError("PlayType expected")
      }
    }
  }
}
