/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module RequiredLoginContainer - wraps routes that need login */
import React from 'react';
import PropTypes from 'prop-types';
import {Redirect} from '@reach/router'

// TODO. Best place for Cognito access parameters.
const AUTH_DOMAIN='auth.eagerwords.com';
const AUTH_CLIENT_ID="changeMe"; // TODO. Add client id.

// TODO. Create token-receiver handler. It should be open since login has not been processed yet.
const gameUrl = "https://eagerwords.com/token-receiver";

// TODO. Move to CognitoUtils.
// TODO. Add: &scope=....&state=randomness.
const mkCognitoLoginUrl = function(authDomain, clientId, redirectUri) {
  return `https://${authDomain}/login?response_type=code&client_id=${clientId}&redirect_uri=${redirectUri}`;
};

const authLoginUrl = mkCognitoLoginUrl(AUTH_DOMAIN, AUTH_CLIENT_ID, gameUrl);

// the response has: code=AUTH_CODE&state=sameRandomness
// TODO. How do we detect an error?

/**
 * Wrapper around routes that needs login.
 */
class RequiredLoginContainer extends React.Component {

  static propTypes = {
    isLoggedIn: PropTypes.bool.isRequired
  };

  render() {
    if (this.props.isLoggedIn)
      return this.props.children;
    else
      return (
        <Redirect to={authLoginUrl} />
      )
  }
}

export default RequiredLoginContainer