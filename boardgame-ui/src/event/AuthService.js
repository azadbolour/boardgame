/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import AppParams from '../util/AppParams';
import {randomString} from '../util/MiscUtil'

// TODO. Add client id.

export const DOMAIN = "eagerwords.com";
export const LOCAL_DOMAIN = "localhost:5000";

export const mkDomain = apiType =>
  (apiType === AppParams.CLIENT_API_TYPE) ? DOMAIN : LOCAL_DOMAIN;

export const CLIENT_ID = "fillMeIn";

const mkRandomState = () => randomString();

// TODO. Need to keep track of the state to compare on redirect.
// Add to loginState??
export const RESPONSE_TYPE_CODE = "code";

export const mkLoginUrl = apiType => {
  let loginParams =
    `responseType=${RESPONSE_TYPE_CODE}&` +
    `redirectUri=${mkLoginRedirectUri}&` +
    `CLIENT_ID=${CLIENT_ID}&state=${mkRandomState()}&` +
    `scope=openid`;

  return (
    (apiType === AppParams.CLIENT_API_TYPE) ?
      `https://auth.${DOMAIN}/login?${loginParams}`
      :
      `https://${LOCAL_DOMAIN}/login?${loginParams}`
  )
};

// TODO. How does the auth server know which use is logging out?

export const mkLogoutUrl = apiType => {
  let logoutParams =
    `redirectUri=${mkLoginRedirectUri}&` +
    `client_id=${CLIENT_ID}&state=${mkRandomState()}&`;

  return (
    (apiType === AppParams.CLIENT_API_TYPE) ?
      `https://auth.${DOMAIN}/logout?${logoutParams}`
      :
      `https://${LOCAL_DOMAIN}/logout?${logoutParams}`
  )
};

export const LOGIN_REDIRECT_PATH = "/login/redirect";
export const LOGOUT_REDIRECT_PATH = "/logout/redirect";

const mkLoginRedirectUri =
    apiType => `https://${mkDomain(apiType)}${LOGIN_REDIRECT_PATH}`;

const mkLogoutRedirectUri =
    apiType => `https://${mkDomain(apiType)}${LOGOUT_REDIRECT_PATH}`;

const mkAuthService = function(appParams) {
  const apiType = appParams.apiType;
  const loginUrl = mkLoginUrl(apiType);
  const logoutUrl = mkLogoutUrl(apiType);

  return {
    login: () => {
      // TODO. fetch login
    },
    logout: () => {
      // TODO. fetch logout
    }
  }
};
