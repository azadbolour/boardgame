/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class GameSummary {
    public final StopInfo stopInfo;
    public final int[] endOfPlayScores;
    public final int[] totalScores;

    @JsonCreator
    public GameSummary(
      @JsonProperty("stopInfo") StopInfo stopInfo,
      @JsonProperty("endOfPlayScores") int[] endOfPlayScores,
      @JsonProperty("totalScores") int[] totalScores
    ) {
        this.stopInfo = stopInfo;
        this.endOfPlayScores = endOfPlayScores;
        this.totalScores = totalScores;
    }

}
