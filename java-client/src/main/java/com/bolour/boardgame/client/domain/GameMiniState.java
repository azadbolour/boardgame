/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class GameMiniState {
    public final int lastPlayScore;
    public final int[] scores;
    public final int numSackTiles;
    public final int trayCapacity;
    public final boolean noMorePlays;

    @JsonCreator
    public GameMiniState(
      @JsonProperty("lastPlayScore") int lastPlayScore,
      @JsonProperty("scores") int[] scores,
      @JsonProperty("numSackTiles") int numSackTiles,
      @JsonProperty("trayCapacity") int trayCapacity,
      @JsonProperty("noMorePlays") boolean noMorePlays
    ) {
        this.lastPlayScore = lastPlayScore;
        this.scores = scores;
        this.numSackTiles = numSackTiles;
        this.trayCapacity = trayCapacity;
        this.noMorePlays = noMorePlays;
    }

}
