/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.benchmark;

public class FinalState extends BaseState {
    public FinalState() {
        super(GameBenchmarkStateId.FINAL);
    }

    @Override
    public boolean isFinalState() {
        return true;
    }
}
