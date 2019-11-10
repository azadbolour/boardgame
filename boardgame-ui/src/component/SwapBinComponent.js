/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module SwapBin */

import React from 'react';
import PropTypes from 'prop-types';
import {mkPiece} from '../domain/Piece';
import SquareComponent from './SquareComponent';
import actions from '../event/GameActions';
// import {stringify} from "../util/Logger";
import * as Style from "../util/StyleUtil";
const ItemTypes = require('./DragDropTypes').ItemTypes;
const DropTarget = require('react-dnd').DropTarget;
const pix=75;
const pixels= pix + 'px';

function colorCodedLegalMoveStyle(colorCoding) {
  return {
    position: 'absolute',
    top: 0,
    left: 0,
    height: pixels,
    width: pixels,
    zIndex: 1,
    opacity: 0.5,
    backgroundColor: colorCoding
  };
}

/**
 * Style for the square - it is relative to its siblings within its parent.
 */
function squareStyle() {
  return {
    position: 'relative',
    color: 'DarkGoldenrod',
    width: pixels,
    height: pixels,
    textAlign: 'center',
    fontFamily: 'Helvetica',
    fontSize: 15,
    fontWeight: 'bold',
    borderStyle: 'solid',
    borderWidth: '3px',
    padding: '1px'
  };
}

let getMonitorPiece = function(monitor) {
  let pieceItem = monitor.getItem();
  return mkPiece(pieceItem.value, pieceItem.id);
};

const pieceDropper = {
  canDrop: function (props, monitor) {
    let piece = getMonitorPiece(monitor);
    let can = props.isTrayPiece(piece) && props.enabled;
    return can;
  },

  drop: function (props, monitor) {
    let piece = getMonitorPiece(monitor);
    actions.swap(piece);
  }
};

function injectedDropTargetProperties(connect, monitor) {
  return {
    connectDropTarget: connect.dropTarget(),
    isOver: monitor.isOver(),
    canDrop: monitor.canDrop()
  };
}

class SwapBinComponent extends React.Component {
  static propTypes = {
    /**
     * Check that piece comes fro the tray - and hence can be swapped.
     */
    isTrayPiece: PropTypes.func.isRequired,

    /**
     * The swap bin is enabled.
     */
    enabled: PropTypes.bool.isRequired,

    /**
     * Is the cursor over the current square?
     */
    isOver: PropTypes.bool.isRequired,

    canDrop: PropTypes.bool.isRequired

    // Note connectDropTarget is also injected.
  };

  render() {
    let connectDropTarget = this.props.connectDropTarget;
    let isOver = this.props.isOver;
    let canDrop = this.props.canDrop;
    let label = "Swap Bin";
    let enabled = this.props.enabled;
    let color = enabled ? 'Chocolate' : Style.disabledColor;
    let backgroundColor = enabled ? 'Khaki' : Style.disabledBackgroundColor;
    // TODO. Could not put line break between two words and have the entire text appear in square boundary.

    return connectDropTarget(
      <div style={squareStyle()}>

        <SquareComponent
          pixels={pix}
          color={color}
          backgroundColor={backgroundColor}
          enabled={enabled}>
          {label}
        </SquareComponent>

        {isOver && !canDrop && <div style={colorCodedLegalMoveStyle('red')} />}
        {!isOver && canDrop && <div style={colorCodedLegalMoveStyle('yellow')} />}
        {isOver && canDrop && <div style={colorCodedLegalMoveStyle('green')} />}

      </div>
    );
  }
}

export default DropTarget(ItemTypes.PIECE, pieceDropper, injectedDropTargetProperties)(SwapBinComponent);