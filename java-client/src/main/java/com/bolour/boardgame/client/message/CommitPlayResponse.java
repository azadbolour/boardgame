/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.Piece;
import com.bolour.boardgame.client.domain.GameMiniState;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class CommitPlayResponse {

    public final GameMiniState gameMiniState;
    public final List<Piece> replacementPieces;

    @JsonCreator
    public CommitPlayResponse(
      @JsonProperty("gameMiniState") GameMiniState gameMiniState,
      @JsonProperty("replacementPieces") List<Piece> replacementPieces) {
        this.gameMiniState = gameMiniState;
        this.replacementPieces = replacementPieces;
    }
}
