/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Piece */

import React from 'react';
import PropTypes from 'prop-types';
import {isDead} from "../domain/Piece";

import {
  DragSource,
} from 'react-dnd';

const ItemTypes = require('./DragDropTypes').ItemTypes;

const letterStyle = {
  fontSize: 15,
  MozUserSelect: 'none',
  WebkitUserSelect: 'none',
  MsUserSelect: 'none',
  userSelect: 'none'
};

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
 * The piece. A draggable item.
 */
// class PieceComponent extends React.Component {
const PieceComponent = (props) => {

    let connectDragSource = props.connectDragSource;
    let connectDragPreview = props.connectDragPreview;
    let isDragging = props.isDragging;
    let letter = props.piece.value;
    if (isDead(letter))
      letter = ""; // Do not render "dead" piece.
    // let worth = Piece.worths[letter];

    // let theDiv =
    return (
      <>
      <div
        ref={isDragging ? connectDragPreview : connectDragSource}
        style={{
          opacity: isDragging ? 0.5 : 1,
          fontSize: 15,
          fontWeight: 'bold',
          cursor: 'move',
          zIndex: 10
        }}
      >
        <div style={letterStyle}>
          {letter}
        </div>
      </div>
      </>
    );
};

PieceComponent.propTypes = {

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

  connectDragPreview: PropTypes.func.isRequired,

  /**
   * Injected - obtained from the 'collect' function.
   */
  isDragging: PropTypes.bool.isRequired
};

export default DragSource(
  ItemTypes.PIECE, pieceDragger,
  (connect, monitor) => ({
    connectDragSource: connect.dragSource(),
    connectDragPreview: connect.dragPreview(),
    isDragging: monitor.isDragging(),
  })
)(PieceComponent)
