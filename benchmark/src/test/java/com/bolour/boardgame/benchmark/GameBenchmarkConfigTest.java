/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.benchmark;

import com.bolour.util.FileUtil;
import com.bolour.util.YamlUtil;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static java.lang.String.format;

public class GameBenchmarkConfigTest {

    private static final Class<?> THE_CLASS = GameBenchmarkConfigTest.class;
    private static final Logger LOGGER = LoggerFactory.getLogger(THE_CLASS);
    private static final String CONFIG_PATH = "com/bolour/boardgame/benchmark/benchmark-config.yml";

    @Test
    public void testReadImmutableConfig() throws Exception {
        String configString = FileUtil.readResourceAsString(THE_CLASS, CONFIG_PATH);
        GameBenchmarkConfig config = YamlUtil.yamlStringToImmutable(configString, GameBenchmarkConfig.class);
        LOGGER.info(format("config read:\n%s", config));
    }
}
