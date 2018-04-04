package com.bolour.boardgame.scala.server.domain.json

import spray.json.{DefaultJsonProtocol, JsString, JsValue, RootJsonFormat, deserializationError}

object JsonUtil {

  def removeQuotes(s: String): String = {
    s.replaceAll("\"", "")
  }

  /**
    * There must be a simpler way to convert a json string that has been
    * quoted by spray, to a simple string value, or to prevent spray to add
    * the quotes in the first place, but I have missed it so far!
    *
    * @param json A JsString presented as a JsValue.
    * @return The enclosed string without quote.
    */
  def unwrapQuotedJsonString(json: JsValue): String = {
    val value = json.asInstanceOf[JsString]
    removeQuotes(value.value)
  }

}
