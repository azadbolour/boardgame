/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.GameMiniState;
import com.bolour.boardgame.client.domain.Piece;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class MachinePlayResponse {

    public final GameMiniState gameMiniState;
    public final List<Piece> playedPieces;

    @JsonCreator
    public MachinePlayResponse(
      @JsonProperty("gameMiniState") GameMiniState gameMiniState,
      @JsonProperty("playedPieces") List<Piece> playedPieces) {
        this.gameMiniState = gameMiniState;
        this.playedPieces = playedPieces;
    }
}
