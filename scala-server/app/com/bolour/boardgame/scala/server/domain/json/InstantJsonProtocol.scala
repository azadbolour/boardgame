package com.bolour.boardgame.scala.server.domain.json

import java.time.Instant

import com.bolour.boardgame.scala.server.domain.json.JsonUtil.unwrapQuotedJsonString
import spray.json.{DefaultJsonProtocol, JsString, JsValue, RootJsonFormat, deserializationError}

object InstantJsonProtocol extends DefaultJsonProtocol {

  implicit object InstantFormat extends RootJsonFormat[Instant] {
    override def write(instant: Instant): JsValue = JsString(instant.toString)

    override def read(json: JsValue): Instant = {
      // TODO. Remove the annoying extra quotes in the first place if possible.
      val string = unwrapQuotedJsonString(json)
      try {
        Instant.parse(string)
      } catch {
        case _: Exception => deserializationError(s"${string} not recognized as [Instant in] time")
      }
    }
  }
}
