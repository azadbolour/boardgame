/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.GameParams;
import com.bolour.boardgame.client.domain.PiecePoint;
import com.bolour.boardgame.client.domain.Piece;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class StartGameRequest {

    public final @JsonProperty("gameParams") GameParams gameParams;
    public final @JsonProperty("initGridPieces") List<PiecePoint> initGridPieces;
    public final @JsonProperty("initUserPieces") List<Piece> initUserPieces;
    public final @JsonProperty("initMachinePieces") List<Piece> initMachinePieces;
    public final @JsonProperty("pointValues") List<List<Integer>> pointValues;

    @JsonCreator
    public StartGameRequest(
      @JsonProperty("gameParams") GameParams gameParams,
      @JsonProperty("initGridPieces") List<PiecePoint> initGridPieces,
      @JsonProperty("initUserPieces") List<Piece> initUserPieces,
      @JsonProperty("initMachinePieces") List<Piece> initMachinePieces,
      @JsonProperty("pointValues") List<List<Integer>> pointValues
    ) {
        this.gameParams = gameParams;
        this.initGridPieces = initGridPieces;
        this.initUserPieces = initUserPieces;
        this.initMachinePieces = initMachinePieces;
        this.pointValues = pointValues;
    }

}
