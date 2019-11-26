
/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import React from 'react';
import {Component} from 'react';
import {Suspense, Fragment} from 'react';
import GameComponent from './GameComponent';
import LandingComponent from './LandingComponent';
import {Auth} from 'aws-amplify';
import {stringify} from "../util/Logger";
import PropTypes from "prop-types";

/**
 * Top-level container. Keep it real simple to begin with and
 * go directly to games if logged in and to the Welcome page if not.
 */

const getUserName = async () => {
  let info = await Auth.currentUserInfo();
  console.log(`getUserName: info: ${stringify(info)}`);
  let userName = undefined;
  if (info)
    userName = info.username;
  return await userName;
};

class HomeContainer extends Component {

  constructor() {
    super();
    this.state = {userName: '' };
  }

  async componentDidMount() {
    const info = await Auth.currentUserInfo();
    if (!info)
      return;
    const userName = info.username;
    this.setState ({ userName: userName});
  }

  // TODO. Present the catch error in LandingComponent.

  render() {
    let props = this.props;
    let userName = this.state.userName;
    if (userName) {
      const ps = {...props, userName: {userName}};
      return (<GameComponent {...ps} />);
    } else
      return (<LandingComponent {...props} />);
  }
}

HomeContainer.propTypes = {
  gameState: PropTypes.object.isRequired,
  gameEventHandler: PropTypes.object.isRequired,
  serverType: PropTypes.string.isRequired
};

export default HomeContainer;
