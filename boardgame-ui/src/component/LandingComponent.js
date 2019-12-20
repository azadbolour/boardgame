/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import React, { Component } from 'react';
import OAuthButton from './OAuthButton';
import Amplify, { Auth, Hub } from 'aws-amplify';
import GameComponent from "./GameComponent";
import {stringify} from "../util/Logger";
import {configuration} from "../aws-exports";
import {userInfoToUser} from "../util/CognitoUtil";

Amplify.configure(configuration);
const auth = configuration.auth;
Auth.configure({ auth });

function ruleStyle(color) {
  if (color === undefined)
    color = 'Black';
  return {
    width: '1000px',
    color: color,
    align: 'left',
    fontSize: 18,
    fontFamily: 'arial',
    borderWidth: '4px',
    borderColor: 'Red',
    margin: 'auto',
    padding: '10px'
  }
}

// TODO. Duplicated from OAuthButton. Remove after merging OAuthButton into this file.
function buttonStyle() {
  let color = 'Chocolate';
  let backgroundColor = 'Khaki';
  return {
    width: '150px',
    height: '50px',
    color: color,
    backgroundColor: backgroundColor,
    align: 'left',
    fontSize: 15,
    fontWeight: 'bold',
    borderWidth: '4px',
    margin: 'auto',
    padding: '2px'
  }
}

class LandingComponent extends Component {
  constructor(props) {
    super(props);
    this.signOut = this.signOut.bind(this);
    // No notification seen for sign in.
    // let the Hub module listen on Auth events
    // The other events are signOut, SignUp. TODO. Catch signUp and enter user in db.
    // Hub.listen('auth', (data) => {
    //   console.log(`Hub notification - data.payload: ${JSON.stringify(data.payload, null, 2)}`);
    //   switch (data.payload.event) {
    //     case 'signIn':
    //       this.setState({authState: 'signedIn', authData: data.payload.data});
    //       break;
    //     case 'signIn_failure':
    //       this.setState({authState: 'signIn', authData: null, authError: data.payload.data});
    //       break;
    //     default:
    //       break;
    //   }
    // });
    this.state = {
      authState: 'loading',
      authData: null,
      authError: null,
      user: null
    }
  }

  componentDidMount() {

    // No notification seen for sign in.
    Hub.listen('auth', (data) => {
      console.log(`Hub notification - data.payload: ${JSON.stringify(data.payload, null, 2)}`);
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

    console.log('on component mount');
    // check the current user when the App component is loaded
    Auth.currentAuthenticatedUser().then(userInfo => {
      console.log(`current authenticated user: ${stringify(userInfo, null, 2)}`);
      let user = userInfoToUser(userInfo);
      console.log(`user: ${stringify(user)}`);
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
    const ps = {...props, user: state.user};
    return (
      <div>
      <div>
          <button
            onClick={this.signOut}
            style={buttonStyle()} >
            SignOut</button>
      </div>
        <pre> </pre>
      <div>
        <GameComponent {...ps} />
      </div>
      </div>
    )
  }

  renderRules() {
    return (
      <div>
        <div style={ruleStyle("#009FFF")}>A Crossword Game</div>
        <div style={ruleStyle("#009FFF")}>Rules</div>
        <ul>
        <li style={ruleStyle()}>
          Points are associated with board locations - not with letters.
        </li>
        <li style={ruleStyle()}>
          The assignment of points to board locations varies from game to game.
        </li>
        <li style={ruleStyle()}>
          A word play accumulates the points of the [new] locations it captures.
        </li>
        <li style={ruleStyle()}>
          A word play on a non-empty board must contain at least one existing letter.
        </li>
        <li style={ruleStyle()}>
          A word play on an empty board is unrestricted.
        </li>
        <li style={ruleStyle()}>
          The played word and any crosswords formed by the play must exist in the
          game's dictionary.
        </li>
        <li style={ruleStyle()}>
          Letters for play are generated randomly based on their frequency in the English lexicon
          (per <a href="http://www.oxfordmathcenter.com/drupal7/node/353">Oxford Math Center</a>).
        </li>
        <li style={ruleStyle()}>
          There is no notion of a container of letters getting depleted.
        </li>
        <li style={ruleStyle()}>
          When no board play is possible, a single letter is swapped by dropping it onto the
          swap bin.
        </li>
        <li style={ruleStyle()}>
          A game ends upon 10 consecutive no-plays [swaps].
        </li>
        <li style={ruleStyle()}>
          Games have a time limit of 1 hour. Longer games are considered
          abandoned and are harvested.
        </li>
        </ul>
      </div>
    )
  }

  render() {
    const { authState } = this.state;
    return (
      <div>
        <div align='center'>
          <div style={{fontSize: "35px", color: "#009FFF", align: 'center', padding: '20px'}}>
          Eager Words
          </div>
        </div>
        <div align='center'>
          {authState === 'loading' && (<div>loading...</div>)}
        </div>
        <div align='center'>
          {authState === 'signIn' && <OAuthButton style={buttonStyle()}/>}
        </div>
          {authState === 'signedIn' && this.renderSignedIn() }
        <div>
        </div>
        <div>
          {authState === 'signIn' && this.renderRules() }
          {authState === 'signIn' &&
          <div>
            <pre> </pre>
            <div style={ruleStyle('#009FFF')}>
              Bolour Computing. 6144 N Rockridge Blvd, Oakland, CA 94618
            </div>
          </div>
          }
        </div>

      </div>
    );
  }
}

export default LandingComponent;