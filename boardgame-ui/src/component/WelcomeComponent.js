/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module WelcomeComponent - home page */
import React from 'react';
import PropTypes from 'prop-types';


const WelcomeComponent = props => {

  // TODO. Add login action. Get appropriate login service. Call its login.

  return (
    <div>
      Welcome to Eager Words

      <button onClick={() => {}}>
        login
      </button>
    </div>
  )
};

export default WelcomeComponent