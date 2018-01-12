/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.Collections;
import java.util.List;

class StopInfo {
    int successivePasses;
    int maxSuccessivePasses;
    boolean isSackEmpty;
    boolean isUserTrayEmpty;
    boolean isMachineTrayEmpty;

    @JsonCreator
    public StopInfo(
      @JsonProperty("successivePasses") int successivePasses,
      @JsonProperty("maxSuccessivePasses") int maxSuccessivePasses,
      @JsonProperty("isSackEmpty") boolean isSackEmpty,
      @JsonProperty("isUserTrayEmpty") boolean isUserTrayEmpty,
      @JsonProperty("isMachineTrayEmpty") boolean isMachineTrayEmpty
    ) {
        this.successivePasses = successivePasses;
        this.maxSuccessivePasses = maxSuccessivePasses;
        this.isSackEmpty = isSackEmpty;
        this.isUserTrayEmpty = isUserTrayEmpty;
        this.isMachineTrayEmpty = isMachineTrayEmpty;
    }
}