/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.benchmark;

import com.bolour.benchmark.*;
import com.bolour.boardgame.client.api.GameClientApi;
import com.bolour.boardgame.client.api.IGameClientApi;
import com.bolour.boardgame.client.domain.Game;
import com.bolour.boardgame.client.domain.GameParams;
import com.bolour.boardgame.client.domain.PlayPiece;
import com.bolour.util.rest.BasicCredentials;

import java.util.List;

import static java.lang.Math.random;
import static java.util.Collections.EMPTY_LIST;

public class PlayerPersona extends AbstractBenchmarkPersona {

    private static final int MAX_PLAYS = 10;

    private static final int DIMENSION = 15;
    private static final int TRAY_CAPACITY = 7;
    private static final String LANGUAGE_CODE = "en";
    private static final String PLAYER = "You"; // TODO. Player name should be a parameter.
    public static final GameParams DEFAULT_GAME_PARAMS =
      new GameParams(DIMENSION, DIMENSION, TRAY_CAPACITY, LANGUAGE_CODE, PLAYER);

    private static final String GAME_SERVICE_NAME = "game";
    public static final String START_METHOD = "start";
    public static final String PLAY_METHOD = "play";
    public static final String END_METHOD = "end";

    private final GameBenchmarkConfig config;
    private final String baseUrl;
    private final BasicCredentials credentials;
    private final IGameClientApi client;

    public PlayerPersona(GameBenchmarkConfig config) {
        super(config.runnerConfig);
        this.config = config;

        baseUrl = config.gameServerUrl; // "http://localhost:6587";
        // TODO. User name and password should be parameters.
        credentials = new BasicCredentials("admin", "admin");
        client = new GameClientApi(baseUrl, credentials);
    }

    @Override
    public AbstractBenchmarkState getInitialState() {
        return new InitialState();
    }

    @Override
    public BenchmarkStateTransition executeInteraction(AbstractBenchmarkState state) {
        BaseState s = (BaseState) state;
        BaseState.GameBenchmarkStateId marker = s.getStateId();
        switch (marker) {
            case INITIAL:
                return doStart((InitialState) s);
            case RUNNING:
                return doRun((RunningState) s);
            case FINAL:
                return BenchmarkStateTransition.noTransition(s);
        }
        return null;
    }

    private BenchmarkStateTransition doStart(InitialState initialState) {
        Game gameDto = client.startGame(DEFAULT_GAME_PARAMS, EMPTY_LIST, EMPTY_LIST, EMPTY_LIST);
        BaseState runningState = new RunningState(gameDto.gameId, 0);
        return new BenchmarkStateTransition(initialState, runningState, mkInteraction(START_METHOD));
    }

    private BenchmarkStateTransition doRun(RunningState runningState) {
        boolean endPlay = maxedOut(runningState) || randomEnd();
        BenchmarkStateTransition transition = endPlay ? end(runningState) : play(runningState);
        return transition;
    }

    private boolean maxedOut(RunningState st) {
        return st.getNumPlays() >= MAX_PLAYS;
    }

    private boolean randomEnd() {
        return random() < (double) config.gameEndProbability;
    }

    private BenchmarkInteraction mkInteraction(String theMethod) {
        return new BenchmarkInteraction(
          new BenchmarkInteractionType(GAME_SERVICE_NAME, theMethod));
    }

    /**
     * For now we are only benchmarking machine plays
     * since they take by far the most time.
     */
    private BenchmarkStateTransition play(RunningState runningState) {
        List<PlayPiece> playPieces = client.machinePlay(runningState.gameId);
        BaseState nextState = runningState.incrementNumPlays();
        return new BenchmarkStateTransition(runningState, nextState, mkInteraction(PLAY_METHOD));
    }

    private BenchmarkStateTransition end(RunningState runningState) {
        client.endGame(runningState.gameId);
        BaseState finalState = new FinalState();
        return new BenchmarkStateTransition(runningState, finalState, mkInteraction(END_METHOD));
    }

    @Override
    public int getThinkTimeMillis(AbstractBenchmarkState state) {
        int baseThinkTime = config.runnerConfig.thinkTimeMillis;
        double rand = random();
        int thinkTime = (int) Math.round(rand * baseThinkTime);
        return thinkTime;
    }
}
