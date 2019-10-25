/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Square */

import React from 'react';
import PropTypes from 'prop-types';

function squareStyle(pixels, backgroundColor, color) {
  const pix = pixels + 'px';
  return {
    backgroundColor: backgroundColor,
    color: color,
    width: pix,
    height: pix,
    lineHeight: pix,
    textAlign: 'center',
    borderStyle: 'solid',
    borderWidth: '1px',
    zIndex: 2
  };
}

/**
 * Plain old board square - does not know about drag and drop.
 */
class SquareComponent extends React.PureComponent {

  static propTypes = {
    pixels: PropTypes.number.isRequired,
    color: PropTypes.string.isRequired,
    backgroundColor: PropTypes.string.isRequired,
    enabled: PropTypes.bool.isRequired
  };

  render() {
    let pixels = this.props.pixels;
    let color = this.props.color;
    let backgroundColor = this.props.backgroundColor;

    return (
      <div style={squareStyle(pixels, backgroundColor, color)}>
        {this.props.children}
      </div>
    );
  }
}

export default SquareComponent;
