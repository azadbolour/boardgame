/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package controllers

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.message._
import com.bolour.boardgame.scala.server.domain.Scorer.Score

import scala.concurrent.Future
import com.typesafe.config.ConfigFactory
import play.api.libs.json._
import play.api.mvc._
import org.scalatestplus.play._
import play.api.test._
import play.api.test.Helpers._
import com.bolour.boardgame.scala.server.service.GameServiceImpl
import controllers.GameJsonSupport._
import org.slf4j.LoggerFactory

class GameControllerSpec extends PlaySpec with Results {

  val logger = LoggerFactory.getLogger(this.getClass)

  // implicit val playerWrites = play.api.libs.json.Json.writes[PlayerDto]

  val languageCode = "tiny"

  // TODO. Move generic test initialization to a base class.

  val config = ConfigFactory.load()
  val service = new GameServiceImpl(config)
  val controller = new GameController(stubControllerComponents(), service)

  service.migrate().get
  service.reset().get

  def decodeJsonContent[DTO](result: Future[Result])(implicit reads: Reads[DTO]): DTO = {
    // TODO. Check for status OK - can also be BadRequest or Unprocessable.
    val bodyJson = contentAsJson(result)
    val jsResult = Json.fromJson[DTO](bodyJson)
    jsResult match {
      case JsSuccess(value, _) => value
      case JsError(errors) => throw new NoSuchElementException(errors.toString)
    }
  }

  // For debugging.
  // logger.info(s"${contentAsString(result)}")

  def mkRequest[DTO](dto: DTO)(implicit writes: Writes[DTO]): FakeRequest[JsValue] =
    FakeRequest().withBody(Json.toJson(dto))

  "game controller" should {
    var theGameId: String = null
    var theUserTrayPieces: List[Piece] = Nil
    var result: Future[Result] = null

    val name = "Bill"
    val dimension = 5
    val gameParams = GameParams(dimension, 5, languageCode, name, PieceGeneratorType.Cyclic)
    val uPieces = List(Piece('B'), Piece('E'), Piece('T')) // User to play "BET".
    val mPieces = List(Piece('S'), Piece('T'), Piece('Z')) // Machine to play "SET" using user's 'E'.
    val startGameRequest = StartGameRequest(gameParams, Nil, uPieces, mPieces)

    val center = dimension/2

    "play a mini game" in {
      val playerDto = new PlayerDto(name)
      result = controller.addPlayer()(mkRequest(playerDto))
      val unit = decodeJsonContent[Unit](result)
      logger.info(s"addPlayer result: ${unit}")

      result = controller.startGame()(mkRequest(startGameRequest))
      val gameDto = decodeJsonContent[GameDto](result)
      logger.info(s"startGame dto result: ${gameDto}")
      gameDto match {
        case GameDto(gameId, responseGameParams, gridPieces, userTrayPieces) =>
          responseGameParams mustEqual gameParams
          gridPieces.size mustEqual 0
          userTrayPieces.size mustEqual gameParams.trayCapacity
          theGameId = gameId
          theUserTrayPieces = userTrayPieces
      }

      val userPlayPieces = List(
        PlayPiece(uPieces(0), Point(center, center - 1), true),
        PlayPiece(uPieces(1), Point(center, center), true),
        PlayPiece(uPieces(2), Point(center, center + 1), true)
      )

      result = controller.commitPlay(theGameId)(mkRequest(userPlayPieces))
      decodeJsonContent[CommitPlayResponse](result) match {
        case CommitPlayResponse(score, replacementPieces) =>
          replacementPieces.size mustEqual 3
      }
      // logger.info(s"${replacementPieces}")

      // TODO. How to make request with no body the PlaySpec way??
      result = controller.machinePlay(theGameId)(FakeRequest())
      decodeJsonContent[MachinePlayResponse](result) match {
        case MachinePlayResponse(score, playedPieces) =>
          playedPieces.size must be > 2
      }

      val swappedPiece = theUserTrayPieces(0)
      result = controller.swapPiece(theGameId)(mkRequest(swappedPiece))
      val newPiece = decodeJsonContent[Piece](result)
      newPiece must not be Piece.noPiece

      result = controller.endGame(theGameId)(FakeRequest())
      val endUnit = decodeJsonContent[Unit](result)
      logger.info(s"end game result: ${endUnit}")
    }

  }
}
