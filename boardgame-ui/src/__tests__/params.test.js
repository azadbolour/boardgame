
import GameParams from "../domain/GameParams"
import {queryParamsToObject} from "../util/UrlUtil";
import {stringify} from "../util/Logger";

const clientApi = 'client';
const serverUrl = 'http://localhost:6587';
const squarePixels = 33;
const urlDimension = 11;
const urlTrayCapacity = 3;

const mkGameParams = function() {
  return {
    appParams: {
      envType: 'dev',
      apiType: clientApi,
      serverUrl: serverUrl,
      inputDevice: 'mouse',
    },
    dimension: 13,
    squarePixels: squarePixels,
    trayCapacity: 7
  }
};

const queryParams = (function() {
  const _params = {
    'dimension': urlDimension,
    'tray-capacity': urlTrayCapacity
  };
  return {
    getParam: function (name) {
      return _params[name];
    }
  }
})();

// TODO. Test all params.

test('query parameters override default parameters', () => {
  const {extracted: gameParams, errorState} = queryParamsToObject(queryParams, GameParams.settableParameters, GameParams.validateParam, mkGameParams);
  expect(gameParams['dimension']).toBe(urlDimension);
  expect(gameParams['trayCapacity']).toBe(urlTrayCapacity);
  expect(gameParams['squarePixels']).toBe(squarePixels);
  const appParams = gameParams.appParams;
  expect(appParams['apiType']).toBe(clientApi);
  expect(appParams['serverUrl']).toBe(serverUrl);
});