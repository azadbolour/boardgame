/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.benchmark;

import com.bolour.benchmark.AbstractBenchmarkState;

/**
 * Base class for game states.
 */
public abstract class BaseState extends AbstractBenchmarkState {

    public enum GameBenchmarkStateId {
        INITIAL, RUNNING, FINAL
    }

    private final GameBenchmarkStateId stateId;

    public BaseState(GameBenchmarkStateId stateId) {
        super();
        this.stateId = stateId;
    }

    public GameBenchmarkStateId getStateId() {
        return stateId;
    }

    @Override
    public String getStateName() {
        return stateId.name();
    }

}
