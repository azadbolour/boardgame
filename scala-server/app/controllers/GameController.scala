/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package controllers

import javax.inject._

import com.bolour.boardgame.scala.common.domain.{Piece, PlayPiece}
import controllers.GameJsonSupport._
import controllers.GameDtoConverters._
import com.bolour.boardgame.scala.common.message._
import com.bolour.boardgame.scala.server.domain.GameExceptions._
import com.bolour.boardgame.scala.server.service.GameService
import org.slf4j.LoggerFactory
import play.api.mvc._

import scala.util.{Failure, Success}
import play.api.libs.json._

/*
 * TODO. Not recommended to use InjectedController. Change to use ControllerComponents parameter.
 * But don't know how to inject that in tests.
 * TODO. Where does the components parameter come from?
 */
@Singleton
// class GameController @Inject() (service: GameService) extends InjectedController {
class GameController @Inject() (cc: ControllerComponents, service: GameService) extends AbstractController(cc) {

  val logger = LoggerFactory.getLogger(this.getClass)

  /** Shorthand for validation errors type defined in JsError. */
  type ValidationErrors = Seq[(JsPath, Seq[JsonValidationError])]

  /**
   * Action for adding a player taking json input.
   */
  def addPlayer = Action(parse.json) { implicit request =>
    logger.info(s"addPlayer json request: ${request.body}")
    val maybeValidPlayerDto = validate[PlayerDto](request)
    processRequest(maybeValidPlayerDto, addPlayerValidated)
  }

  /**
    * Action for adding a player once json input is validated.
    * Kept public for testing.
    */
  def addPlayerValidated(dto: PlayerDto) = {
    logger.info(s"addPlayer playerDto: ${dto}")
    val player = fromPlayerDto(dto)
    val triedUnit = service.addPlayer(player)
    triedUnit match {
      case Failure(ex) =>
        logger.error("addPlayer failure", ex)
        unprocessable(ex)
      case Success(_) =>
        logger.info("addPlayer success")
        Ok(Json.toJson(()))
    }
  }

  /**
   * Action for starting a game taking json input.
   */
  def startGame = Action(parse.json) { implicit request =>
    logger.info(s"startGame json request: ${request.body}")
    val maybeValidStartGameRequest = validate[StartGameRequest](request)
    processRequest(maybeValidStartGameRequest, startGameValidated)
  }

  /**
    * Action for starting a game once json input is validated.
    * Kept public for testing.
    */
  def startGameValidated(startGameRequest: StartGameRequest) = {
    logger.info(s"startGame startGameRequest: ${startGameRequest}")
    startGameRequest match {
      case StartGameRequest(gameParams, gridPieces, initUserPieces, initMachinePieces, pointValues) => {
        val triedStart = service.startGame(gameParams, gridPieces, initUserPieces, initMachinePieces, pointValues)
        triedStart match {
          case Failure(ex) =>
            logger.error("startGame failure", ex)
            unprocessable(ex)
          case Success(gameState) => {
            val gameDto = mkStartGameResponse(gameParams, gameState)
            logger.info(s"startGame success gameDto: ${gameDto}")
            Ok(Json.toJson(gameDto))
          }
        }
      }
    }
  }

  // TODO. Change all logging to debug.

  /**
    * Action for committing a play taking json input.
    */
  def commitPlay(gameId: String) = Action(parse.json) { implicit request =>
    logger.info(s"commitPlay: json request: ${request.body}")
    val maybeValidPlayPieces = validate[List[PlayPiece]](request)
    processGameRequest(gameId, maybeValidPlayPieces, commitPlayValidated)
  }

  def commitPlayValidated(gameId: String)(playPieces: List[PlayPiece]) = {
    logger.info(s"commitPlay play pieces: ${playPieces}")
    val triedCommit = service.commitPlay(gameId, playPieces)
    triedCommit match {
      case Failure(ex) =>
        logger.error("commitPlay failure", ex)
        unprocessable(ex)
      case Success((miniState, replacementPieces)) =>
        logger.info(s"commitPlay success - replacements: ${replacementPieces}, mini state: ${miniState}")
        val response = CommitPlayResponse(miniState, replacementPieces)
        Ok(Json.toJson(response))
    }
  }

  // def machinePlay(gameId: String) = Action(parse.json) { implicit request =>
  def machinePlay(gameId: String) = Action { implicit request =>
    logger.info(s"machinePlay")
    val triedMachinePlay = service.machinePlay(gameId)
    triedMachinePlay match {
      case Failure(ex) =>
        logger.info("machinePlay failure", ex)
        unprocessable(ex)
      case Success((miniState, playedPieces)) =>
        logger.info(s"machinePlay success - playedPieces: ${playedPieces}, mini state: ${miniState}")
        val response = MachinePlayResponse(miniState, playedPieces)
        Ok(Json.toJson(response))
    }
  }

  def swapPiece(gameId: String) = Action(parse.json) { implicit request =>
    logger.info(s"swapPiece: json request: ${request.body}")
    val maybeValidPiece = validate[Piece](request)
    processGameRequest(gameId, maybeValidPiece, swapPieceValidated)
  }

  def swapPieceValidated(gameId: String)(piece: Piece) = {
    logger.info(s"swapPiece piece: ${piece}")
    val triedSwap = service.swapPiece(gameId, piece)
    triedSwap match {
      case Failure(ex) =>
        logger.error("swapPiece failure", ex)
        unprocessable(ex)
      case Success((miniState, newPiece)) =>
        logger.info(s"swapPiece success - new piece: ${newPiece}, mini state: ${miniState}")
        val response = SwapPieceResponse(miniState, newPiece)
        Ok(Json.toJson(response))
    }
  }

  // def endGame(gameId: String) = Action(parse.json) { implicit request =>
  def closeGame(gameId: String) = Action { implicit request =>
    logger.info(s"closeGame")
    val triedSummary = service.endGame(gameId)
    triedSummary match {
      case Failure(ex) =>
        logger.error("closeGame failure", ex)
        unprocessable(ex)
      case Success(summary) =>
        logger.info("closeGame success")
        Ok(Json.toJson(summary))
    }

  }

  private def processRequest[DTO](maybeValid: JsResult[DTO], validProcessor: DTO => Result) =
    maybeValid.fold(badRequest, validProcessor)

  private def processGameRequest[DTO](gameId: String, maybeValid: JsResult[DTO],
    validProcessor: String => DTO => Result) = maybeValid.fold(badRequest, validProcessor(gameId))

  private def validate[Body](request: Request[JsValue])(implicit reads: Reads[Body]) = request.body.validate[Body]

  private def badRequest = (errors: ValidationErrors) => BadRequest(JsError.toJson(errors))

  private def unprocessable(th: Throwable) = {

    def jsonError[DTO](dto: DTO)(implicit writes: Writes[DTO]) = UnprocessableEntity(Json.toJson(dto))

    val ex: GameException = th match {
      case gameEx: GameException => gameEx
      case _ => InternalGameException("internal error", th)
    }

    ex match {
      case ex: MissingPieceException => jsonError(toMissingPieceErrorDto(ex))
      case ex: MissingGameException => jsonError(toMissingGameErrorDto(ex))
      case ex: MissingPlayerException => jsonError(toMissingPlayerErrorDto(ex))
      case ex: SystemOverloadedException => jsonError(toSystemOverloadedErrorDto(ex))
      case ex: InvalidWordException => jsonError(toInvalidWordErrorDto(ex))
      case ex: InvalidCrosswordsException => jsonError(toInvalidCrosswordsErrorDto(ex))
      case ex: UnsupportedLanguageException => jsonError(toUnsupportedLanguageErrorDto(ex))
      case ex: MissingDictionaryException => jsonError(toMissingDictionaryErrorDto(ex))
      case ex: MalformedPlayException => jsonError(toMalformedPlayErrorDto(ex))
      case ex: InternalGameException => jsonError(toInternalErrorDto(ex))
    }
  }

}
