/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * Create the login state - it just includes the opaque authorization token.
 * The token is insecure within the browser. It is passed to the backend and
 * there exchanged securely (by using the client secret) with an access token.
 */
export const mkLoginState = function(authToken) {
  return {
    authToken,
    isUserLoggedIn : this.authToken !== undefined
  }
};