/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Piece */

import React from 'react';
const ItemTypes = require('./DragDropTypes').ItemTypes;
const DragSource = require('react-dnd').DragSource;
import logger from "../util/Logger";
const PropTypes = React.PropTypes;
import {stringify} from "../util/Logger";

const pieceDragger = {
  /**
   * Return the drag item: an arbitrary plain JS object
   * providing information about the dragged element.
   * The drag item is distinct from the source component
   * of the drag.
   */
  beginDrag: function (props) {
    let piece = props.piece;
    // console.log(`begin drag: ${stringify(piece)}`);
    // Must return a plain object.
    let item = {
      value: piece.value,
      id: piece.id,
    };
    return item;
  },

  canDrag(props, monitor) {
    let can = props.canMovePiece(props.piece);
    // console.log(`canDrag: ${can} - ${stringify(props.piece)}`);
    return can;
  },

  endDrag: function(props, monitor, component) {
     // console.log(`end drag - dropped: ${monitor.didDrop()}`);
  }
};

/**
 * Get dnd properties to be injected into the drag source component.
 * This is called a 'collect' function in the react dnd jargon.
 *
 * @param connect DragSourceConnector - see React dnd docs.
 * @param monitor DragSourceMonitor - see React dnd docs.
 * @returns Plain object including properties to inject into
 * the dragged source component.
 */
function injectedDragSourceProperties(connect, monitor) {
  return {
    connectDragSource: connect.dragSource(),
    isDragging: monitor.isDragging()
  }
}

/**
 * The piece. A draggable item.
 */
const PieceComponent = React.createClass({
  propTypes: {

    /**
     * The immutable state of the piece.
     * TODO. How to add isRequired with type constraint?
     */
    piece: PropTypes.object.isRequired,

    /**
     * Function that takes a piece and determines if it can be moved
     * (based on its current location and move status). 
     */
    canMovePiece: PropTypes.func.isRequired,

    /**
     * Injected - obtained from the 'collect' function.
     */
    connectDragSource: PropTypes.func.isRequired,

    /**
     * Injected - obtained from the 'collect' function.
     */
    isDragging: PropTypes.bool.isRequired
  },

  render: function () {
    let connectDragSource = this.props.connectDragSource;
    let isDragging = this.props.isDragging;

    return connectDragSource(
      <div style={{
        opacity: isDragging ? 0.5 : 1,
        fontSize: 23,
        fontWeight: 'bold',
        cursor: 'move'
      }}>
        {this.props.piece.value}
      </div>
    );
  }
});

export default DragSource(ItemTypes.PIECE, pieceDragger, injectedDragSourceProperties)(PieceComponent);

export {PieceComponent as OriginalPieceComponent};