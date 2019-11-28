/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import React, { Component } from 'react';
import OAuthButton from './OAuthButton';
import Amplify, { Auth, Hub } from 'aws-amplify';
import {configuration} from '../aws-exports';
import GameComponent from "./GameComponent";
import {stringify} from "../util/Logger"; // your Amplify configuration

Amplify.configure(configuration);
const auth = configuration.auth;
Auth.configure({ auth });

class LandingComponent extends Component {
  constructor(props) {
    super(props);
    this.signOut = this.signOut.bind(this);
    // let the Hub module listen on Auth events
    Hub.listen('auth', (data) => {
      console.log(`auth response - data.payload: ${stringify(data.payload)}`);
      switch (data.payload.event) {
        case 'signIn':
          this.setState({authState: 'signedIn', authData: data.payload.data});
          break;
        case 'signIn_failure':
          this.setState({authState: 'signIn', authData: null, authError: data.payload.data});
          break;
        default:
          break;
      }
    });
    this.state = {
      authState: 'loading',
      authData: null,
      authError: null,
      user: null
    }
  }

  componentDidMount() {
    console.log('on component mount');
    // check the current user when the App component is loaded
    Auth.currentAuthenticatedUser().then(user => {
      console.log(`current authenticated user: ${stringify(user)}`);
      this.setState({authState: 'signedIn', user: user});
    }).catch(e => {
      console.log(`error is getting current authenticated user: ${stringify(e)}`);
      this.setState({authState: 'signIn', user: null});
    });
  }

  signOut() {
    Auth.signOut().then(() => {
      this.setState({authState: 'signIn'});
    }).catch(e => {
      console.log(e);
    });
  }

  renderSignedIn() {
    const state = this.state;
    const props = this.props;
    const ps = {...props, userName: state.user};
    return (
      <div>
        <div>
          <button onClick={this.signOut}>Sign out</button>}
        </div>
        <GameComponent {...ps} />
      </div>
    )
  }

  render() {
    const { authState } = this.state;
    const signedInRendered = this.renderSignedIn();
    return (
      <div>
        {authState === 'loading' && (<div>loading...</div>)}
        {authState === 'signIn' && <OAuthButton/>}
        {authState === 'signedIn' && {signedInRendered} }
      </div>
    );
  }
}

export default LandingComponent;