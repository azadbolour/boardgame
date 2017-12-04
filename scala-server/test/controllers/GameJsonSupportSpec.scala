package controllers

import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory
import play.api.libs.json.{JsError, JsString, JsSuccess, Json}
import com.bolour.boardgame.scala.common.domain.PieceGeneratorType
import com.bolour.boardgame.scala.common.domain.PieceGeneratorType.PieceGeneratorType
import controllers.GameJsonSupport._

class GameJsonSupportSpec extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)

  "piece generator type info" should "get values" in {
    logger.info(s"${PieceGeneratorType.values}")
    val jsonString = "Cyclic"
    val jsValue = JsString(jsonString)
    val result = Json.fromJson[PieceGeneratorType](jsValue)
    result match {
      case JsSuccess(genType, _) => println(s"${genType}")
      case JsError(ex) =>
        logger.error(s"${ex}")
        throw new Exception(s"${ex}")
    }
    println(s"${result}")
  }
}
