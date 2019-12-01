/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module AuthParams - authentication parameters */

/** Contains the production authentication configuration for Cognito. */
import {configuration} from './aws-exports';

/*
 * Use http for redirects to localhost for testing, since localhost
 * does not have a certificate and the browser would reject https.
 */

const devRedirectSignIn = 'http://localhost:3000/';
const devRedirectSignOut = 'http://localhost:3000';

const updateAuthConfiguration = function(conf, redirectSignIn, redirectSignOut) {
  const auth = conf.Auth;
  const oauth = auth.oauth;
  return {
    ...conf,
    Auth: {
      ...auth,
      oauth: {
        ...oauth,
        redirectSignIn,
        redirectSignOut
      }
    }
  }
};

/**
 * Get the cognito auth configuration for the given environment.
 *
 * @param envType The environment - default is 'dev'.
 */
export const getAuthConfiguration = function(envType) {
  if (envType === 'prod')
    return configuration;
  else
    return updateAuthConfiguration(configuration, devRedirectSignIn, devRedirectSignOut);
};
