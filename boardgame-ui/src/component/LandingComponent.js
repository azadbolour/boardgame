/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module LandingComponent - home page */
import React, { Component } from 'react';

/**
 * User lands on this page if not logged in.
 */
const LandingComponent = props => {
  const login = function() {
    props.history.push('/games');
  };

  return (
    <button onClick={login}>Signin/Signup</button>
  );
};

export default LandingComponent;