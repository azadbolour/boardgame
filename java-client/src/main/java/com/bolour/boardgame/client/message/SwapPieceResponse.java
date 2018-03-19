/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.GameMiniState;
import com.bolour.boardgame.client.domain.Piece;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class SwapPieceResponse {

    public final GameMiniState gameMiniState;
    public final Piece piece;

    @JsonCreator
    public SwapPieceResponse(
      @JsonProperty("gameMiniState") GameMiniState gameMiniState,
      @JsonProperty("piece") Piece piece) {
        this.gameMiniState = gameMiniState;
        this.piece = piece;
    }
}
