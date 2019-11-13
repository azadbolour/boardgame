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
const SquareComponent = ({pixels, color, backgroundColor, enabled, children}) => (
  <div style={squareStyle(pixels, backgroundColor, color)}>
    {children}
  </div>
);


SquareComponent.propTypes = {
  pixels: PropTypes.number.isRequired,
  color: PropTypes.string.isRequired,
  backgroundColor: PropTypes.string.isRequired,
  enabled: PropTypes.bool.isRequired
};


export default SquareComponent;
