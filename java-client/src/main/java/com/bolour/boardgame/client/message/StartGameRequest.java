/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.GameParams;
import com.bolour.boardgame.client.domain.InitPieces;
import com.bolour.boardgame.client.domain.PiecePoint;
import com.bolour.boardgame.client.domain.Piece;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class StartGameRequest {

    public final @JsonProperty("gameParams") GameParams gameParams;
    public final @JsonProperty("initPieces") InitPieces initPieces;
    public final @JsonProperty("pointValues") List<List<Integer>> pointValues;

    @JsonCreator
    public StartGameRequest(
      @JsonProperty("gameParams") GameParams gameParams,
      @JsonProperty("initPieces") InitPieces initPieces,
      @JsonProperty("pointValues") List<List<Integer>> pointValues
    ) {
        this.gameParams = gameParams;
        this.initPieces = initPieces;
        this.pointValues = pointValues;
    }

}
