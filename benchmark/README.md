
# Benchmarking Sub-Project for Boardgame

## Overview

This sub-project is dependent on the azadbolour/benchmark library hosted at
bintray jCenter: https://jcenter.bintray.com. Make sure your maven settings.xml
in $HOME/.m2 configures that repository in its profiles.

Please refer to the [the benchmark
library README](https://github.com/azadbolour/benchmark/blob/master/README.md) for
information about the basic structure of benchmarks.

To run a benchmark:

- Start the Haskell game server separately.

- Set the benchmark parameters in a yaml configuration file (see
  benchmark-config.yml for a sample) and then invoke the script run.sh giving it
  your yaml configuration file.

