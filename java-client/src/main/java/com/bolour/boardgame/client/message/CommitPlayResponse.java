/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.Piece;
import com.bolour.boardgame.client.domain.GameMiniState;
import com.bolour.boardgame.client.domain.Point;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class CommitPlayResponse {

    public final GameMiniState gameMiniState;
    public final List<Piece> replacementPieces;
    public final List<Point> deadPoints;

    @JsonCreator
    public CommitPlayResponse(
      @JsonProperty("gameMiniState") GameMiniState gameMiniState,
      @JsonProperty("replacementPieces") List<Piece> replacementPieces,
      @JsonProperty("deadPoints") List<Point> deadPoints) {
        this.gameMiniState = gameMiniState;
        this.replacementPieces = replacementPieces;
        this.deadPoints = deadPoints;
    }
}
