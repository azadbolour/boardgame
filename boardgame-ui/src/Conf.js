
// Default configuration parameters.
// Poor man's configuration file for the UI. TODO. Better option?
// Copy correct version for production in the build process.

export const gameConf = {
  appParams: {
    envType: 'dev',
    apiType: 'client',
    serverUrl: 'http://localhost:6587',
    inputDevice: 'mouse',
  },
  'dimension': 13,
  'squarePixels': 33,
  'trayCapacity': 7
};