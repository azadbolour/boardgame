/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package controllers

import com.bolour.boardgame.scala.common.domain.PieceGeneratorType._
import com.bolour.boardgame.scala.common.domain._
import play.api.libs.json.Json.{reads, writes}
import com.bolour.boardgame.scala.common.message._
import play.api.libs.json._

/**
  * Implicit JSON readers and writers for game dto objects.
  */
object GameJsonSupport {
  implicit val charReads: Reads[Char] = new Reads[Char] {
    def reads(json: JsValue) = Json.fromJson[String](json) map { _.head }
  }
  implicit val pieceGeneratorTypeReads: Reads[PieceGeneratorType] = new Reads[PieceGeneratorType] {
    def reads(json: JsValue) = Json.fromJson[String](json) map { PieceGeneratorType.withName(_) }
    // TODO. Throws NoSuchElementException. Is it consistent with Play validation exceptions.
  }

  /**
    * The json encoding of unit.
    *
    * Treat unit as an empty tuple which is encoded as an array of its field values.
    * The [String] tye parameter is provided to keep the compiler happy
    * (since String is implicitly convertible to json).
    */
  implicit val unitReads: Reads[Unit] = new Reads[Unit] {
    def reads(json: JsValue) = {
      val result = Json.fromJson[List[String]](json)
      result.get match {
        case Nil => JsSuccess(())
        case _ => throw new IllegalArgumentException(s"unitRead: ${json.toString}")
      }
    }
  }

  implicit val gameParamsReads = reads[GameParams]
  implicit val pieceReads = reads[Piece]
  implicit val pointReads = reads[Point]
  implicit val gridPieceReads = reads[GridPiece]
  implicit val playerDtoReads = reads[PlayerDto]
  implicit val gameDtoReads = reads[GameDto]
  implicit val startGameRequestReads = reads[StartGameRequest]
  implicit val playPieceReads = reads[PlayPiece]
  implicit val commitPlayResponseReads = reads[CommitPlayResponse]
  implicit val machinePlayResponseReads = reads[MachinePlayResponse]


  implicit val charWrites: Writes[Char] = new Writes[Char] {
    def writes(o: Char) = Json.toJson[String](o.toString)
  }

  implicit val pieceGeneratorTypeWrites: Writes[PieceGeneratorType] = new Writes[PieceGeneratorType] {
    def writes(o: PieceGeneratorType) = Json.toJson[String](o.toString)
  }

  implicit val unitWrites: Writes[Unit] = new Writes[Unit] {
    def writes(o: Unit) = Json.toJson(List[String]())
  }

  implicit val gameParamsWrites = writes[GameParams]
  implicit val pieceWrites = writes[Piece]
  implicit val pointWrites = writes[Point]
  implicit val gridPieceWrites = writes[GridPiece]
  implicit val playerDtoWrites = writes[PlayerDto]
  implicit val gameDtoWrites = writes[GameDto]
  implicit val startGameRequestWrites = writes[StartGameRequest]
  implicit val playPieceWrites = writes[PlayPiece]
  implicit val commitPlayResponseWrites = writes[CommitPlayResponse]
  implicit val machinePlayResponseWrites = writes[MachinePlayResponse]

  implicit val missingPieceErrorDtoWrites = writes[MissingPieceErrorDto]
  implicit val missingGameErrorDtoWrites = writes[MissingGameErrorDto]
  implicit val missingPlayerErrorDtoWrites = writes[MissingPlayerErrorDto]
  implicit val systemOverloadedErrorDtoWrites = writes[SystemOverloadedErrorDto]
  implicit val invalidWordErrorDtoWrites = writes[InvalidWordErrorDto]
  implicit val invalidCrosswordsErrorDtoWrites = writes[InvalidCrosswordsErrorDto]
  implicit val unsupportedLanguageErrorDtoWrites = writes[UnsupportedLanguageErrorDto]
  implicit val missingDictionaryErrorDtoWrites = writes[MissingDictionaryErrorDto]
  implicit val internalErrorDtoWrites = writes[InternalErrorDto]


  // def unitJson = Json.toJson(List[String]())
}
