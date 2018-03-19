/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.benchmark;

public class InitialState extends BaseState {
    public InitialState() {
        super(GameBenchmarkStateId.INITIAL);
    }

    @Override
    public boolean isFinalState() {
        return false;
    }
}
