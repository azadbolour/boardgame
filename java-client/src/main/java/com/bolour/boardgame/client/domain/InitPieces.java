/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class InitPieces {

    public final @JsonProperty("boardPiecePoints") List<PiecePoint> boardPiecePoints;
    public final @JsonProperty("userPieces") List<Piece> userPieces;
    public final @JsonProperty("machinePieces") List<Piece> machinePieces;

    @JsonCreator
    public InitPieces(
      @JsonProperty("boardPiecePoints") List<PiecePoint> boardPiecePoints,
      @JsonProperty("userPieces") List<Piece> userPieces,
      @JsonProperty("machinePieces") List<Piece> machinePieces
    ) {
        this.boardPiecePoints = boardPiecePoints;
        this.userPieces = userPieces;
        this.machinePieces = machinePieces;
    }

}
