/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.benchmark;

import com.bolour.benchmark.BenchmarkRunnerConfig;
import com.bolour.util.YamlUtil;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;
import org.yaml.snakeyaml.representer.Representer;

import java.io.IOException;
import java.util.Map;

import static com.bolour.util.FileUtil.readFileAsString;

/**
 * Configuration of the game benchmark.
 */
public class GameBenchmarkConfig {

    private static final Class<?> theClass = GameBenchmarkConfig.class;
    private static final Logger LOGGER = LoggerFactory.getLogger(theClass);

    public final BenchmarkRunnerConfig runnerConfig;
    public final String gameServerUrl;
    public final float gameEndProbability;

    // Constructor annotations are necessary for deserializing into an immutable class.

    @JsonCreator
    public GameBenchmarkConfig(
      @JsonProperty("runnerConfig") BenchmarkRunnerConfig runnerConfig,
      @JsonProperty("gameServerUrl") String gameServerUrl,
      @JsonProperty("gameEndProbability") float gameEndProbability
    ) {
        this.runnerConfig = runnerConfig;
        this.gameServerUrl = gameServerUrl;
        this.gameEndProbability = gameEndProbability;
    }

    public static GameBenchmarkConfig readGameBenchmarkConfig(String configPath) throws IOException {
        String configString = readFileAsString(configPath);
        GameBenchmarkConfig config = YamlUtil.yamlStringToImmutable(configString, GameBenchmarkConfig.class);

        LOGGER.info(config.toString());
        return config;
    }

    @Override
    public String toString() {
        return "GameBenchmarkConfig{" +
          "runnerConfig=" + runnerConfig +
          ", gameServerUrl='" + gameServerUrl + '\'' +
          ", gameEndProbability=" + gameEndProbability +
          '}';
    }

}
