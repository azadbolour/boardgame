/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module WelcomeComponent - home page */
import React from 'react';
import PropTypes from 'prop-types';

class MockLoginComponent extends React.Component {

  simulateLoginFlow() {
    // TODO.
  }

  render() {
    return (
      <div>
        <button onClick={() => {this.simulateLoginFlow()}}>
          login as guest
        </button>
      </div>
    )
  }
}

export default MockLoginComponent