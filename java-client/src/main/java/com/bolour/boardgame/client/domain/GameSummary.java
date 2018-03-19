/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class GameSummary {
    public final StopInfo stopInfo;

    @JsonCreator
    public GameSummary(
      @JsonProperty("stopInfo") StopInfo stopInfo
    ) {
        this.stopInfo = stopInfo;
    }

}
