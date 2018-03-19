/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.benchmark;

public class RunningState extends BaseState {
    public final int numPlays;
    public final String gameId;

    public RunningState(String gameId, int numPlays) {
        super(GameBenchmarkStateId.RUNNING);
        this.gameId = gameId;
        this.numPlays = numPlays;
    }

    @Override
    public boolean isFinalState() {
        return false;
    }

    public int getNumPlays() {
        return numPlays;
    }

    public RunningState incrementNumPlays() {
        return new RunningState(gameId, numPlays + 1);
    }


}
