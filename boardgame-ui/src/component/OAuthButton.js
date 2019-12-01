
import { withOAuth } from 'aws-amplify-react';
import React, { Component } from 'react';
import * as Style from "../util/StyleUtil";

// TODO. Merge into the landing page. use the same buttonStyle.
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

class OAuthButton extends Component {
  render() {
    return (
      <button
        onClick={this.props.OAuthSignIn}
        style={buttonStyle()}
      >
        SignIn/SignUp
      </button>
    )
  }
}

export default withOAuth(OAuthButton);