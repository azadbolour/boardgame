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

public class HandShakeResponse {

    public final String serverType;
    public final String apiVersion;

    @JsonCreator
    public HandShakeResponse(
      @JsonProperty("serverType") String serverType,
      @JsonProperty("apiVersion") String apiVersion) {
        this.serverType = serverType;
        this.apiVersion = apiVersion;
    }
}
