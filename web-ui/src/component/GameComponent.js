/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Game */
const DragDropContext = require('react-dnd').DragDropContext;
const HTML5Backend = require('react-dnd-html5-backend');
import React from 'react';
import ReactList from 'react-list';
import * as Game from '../domain/Game';
import TrayComponent from './TrayComponent';
import BoardComponent from './BoardComponent';
import SwapBinComponent from './SwapBinComponent';
import actions from '../event/GameActions';
import {stringify} from "../util/Logger";
import * as Style from "../util/StyleUtil";

const PropTypes = React.PropTypes;

function buttonStyle(enabled) {
  let color = enabled ? 'Chocolate' : Style.disabledColor;
  let backgroundColor = enabled ? 'Khaki' : Style.disabledBackgroundColor;
   return {
    width: '80px',
    height: '60px',
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

const paddingStyle = {
  padding: '10px'
};

const labelStyle = {
  color: 'Brown',
  align: 'left',
  fontSize: 20,
  fontFamily: 'Arial',
  fontWeight: 'bold',
  margin: 'auto',
  padding: '2px'
};

const fieldStyle = {
  color: 'Red',
  backgroundColor: 'Khaki',
  align: 'left',
  fontSize: 20,
  fontWeight: 'bold',
  margin: 'auto',
  padding: '2px'
};

const tooltipStyle = function(visible) {
  let visibility = visible ? 'visible' : 'hidden';
  let display = visible ? 'inline' : 'none';
  return {
    visibility: visibility,
    display: display,
    width: '150px',
    backgroundColor: 'Khaki',
    color: 'Red',
    fontFamily: 'Arial',
    fontSize: 18,
    textAlign: 'left',
    padding: '5px',
    borderRadius: '6px',
    position: 'absolute',
    zIndex: 1
  }
};

const START = "start";
const END = "end";
const COMMIT = "commit";
const REVERT = "revert";

/**
 * The entire game UI component including the board and game buttons.
 */
const GameComponent = React.createClass({

  getInitialState: function() {
    return {tipButton: ''};
  },

  propTypes: {
    /**
     * The contents of the grid. It is a 2-dimensional array of strings.
     */
    game: PropTypes.object.isRequired,
    status: PropTypes.string,
    auxGameData: PropTypes.object.isRequired
  },

  tipOn(tipButton) {
    this.setState({tipButton: tipButton});
  },

  tipOff() {
    this.setState({tipButton: ''});
  },

  isTipOn(tipButton) {
    return this.state.tipButton === tipButton;
  },

  overStart() {

  },

  commitPlay: function() {
    actions.commitPlay();
    // TODO. If server rejects the word - undo the play.
  },

  revertPlay: function() {
    actions.revertPlay();
  },

  startGame: function() {
    actions.start(this.props.game.gameParams);
  },

  endGame: function() {
    actions.end();
  },

  renderWord: function(index, key) {
    let words = this.props.auxGameData.wordsPlayed;
    let l = words.length
    let word = words[index].word;
    let color = index === l - 1 ? 'FireBrick' : 'Chocolate';
    return <div key={key}
                style={{
                  color: color,
                  padding: '3px'
                  }}>{word}</div>;
  },

  scrollToLastWord: function() {
    this.wordReactListComponent.scrollTo(this.props.auxGameData.wordsPlayed.length - 1);
  },

  componentDidMount: function() {
    this.scrollToLastWord();
  },

  componentDidUpdate: function(prevPros, prevState) {
    this.scrollToLastWord();
  },

  render: function () {
    let game = this.props.game;
    let running = game.running();
    let hasUncommittedPieces = game.numPiecesInPlay() > 0;
    let canMovePiece = game.canMovePiece.bind(game);
    let board = game.board;
    let trayPieces = game.tray.pieces;
    let squarePixels = this.props.game.squarePixels;
    let pointsInPlay = board.getUserMovePlayPieces().map(pp => pp.point);
    let isLegalMove = game.legalMove.bind(game);
    let status = this.props.status;
    let userName = game.gameParams.appParams.userName;
    let userScore = game.score[Game.USER_INDEX];
    let machineScore = game.score[Game.MACHINE_INDEX];
    let isTrayPiece = game.tray.isTrayPiece.bind(game.tray);
    let isError = (status !== "OK" && status !== "game over"); // TODO. This is a hack! Better indication of error and severity.
    let enableStart = !running && !isError;
    let enableCommit = running && hasUncommittedPieces;
    let enableRevert = running && hasUncommittedPieces;
    let scoreMultipliers = game.scoreMultipliers;
    // console.log(`BoardComponent: ${stringify(scoreMultipliers.rows())}`)

    // TODO. Use individual function components where possible.
    // TODO. Break up game component structure into modular pieces.

    /*
     * Note. Do not use &nbsp; for spaces in JSX. It sometimes
     * comes out as circumflex A (for example in some cases
     * with the Haskell Servant web server). Have not been
     * able to figure why and in what contexts, or how much
     * of it is a React issue and how much Servant.
     *
     * Use <pre> </pre> for spaces instead.
    */

    return (
      <div>
        <div style={{display: 'flex', flexDirection: 'row'}}>

          <div style={{display: 'flex',
                        flexDirection: 'column',
                        borderStyle: 'solid',
                        borderWidth: '5px',
                        padding: '1px',
                        backgroundColor: 'Wheat',
                        color: 'Wheat'}}>

            <div style={paddingStyle}>
              <button
                onClick={() => {this.tipOff(); this.startGame()}}
                onMouseOver={() => this.tipOn(START)}
                onMouseOut={() => this.tipOff()}
                style={buttonStyle(enableStart)}
                disabled={!enableStart}
              >
                Start Game
              </button>
              {!enableStart && this.isTipOn(START) &&
              <div style={tooltipStyle(enableStart)}>start a new game</div>
              }
            </div>

            <pre></pre>
            <div style={paddingStyle}>
              <button
                onClick={() => {this.tipOff(); this.commitPlay()}}
                onMouseOver={() => this.tipOn(COMMIT)}
                onMouseOut={() => this.tipOff()}
                style={buttonStyle(enableCommit)}
                disabled={!enableCommit}
              >Commit Play
              </button>
              {enableCommit && this.isTipOn(COMMIT) &&
              <div style={tooltipStyle(enableCommit)}>commit the moves in current play</div>
              }
            </div>

            <pre></pre>
            <div style={paddingStyle}>
              <button
                onClick={() => {this.tipOff(); this.revertPlay()}}
                onMouseOver={() => this.tipOn(REVERT)}
                onMouseOut={() => this.tipOff()}
                style={buttonStyle(enableRevert)}
                disabled={!enableRevert}
              >
                Revert Play
              </button>
              {enableRevert && this.isTipOn(REVERT) &&
              <div style={tooltipStyle(enableRevert)}>revert the moves of the current play</div>
              }
            </div>

          </div>

          <pre>   </pre>

          <div style={{display: 'flex', flexDirection: 'column'}}>
            <TrayComponent
              pieces={trayPieces}
              canMovePiece={canMovePiece}
              squarePixels={squarePixels}
              enabled={running} />
            <pre> </pre>
            <BoardComponent
              board={board}
              pointsInPlay={pointsInPlay}
              isLegalMove={isLegalMove}
              canMovePiece={canMovePiece}
              squarePixels={squarePixels}
              scoreMultipliers={scoreMultipliers}
              enabled={running}
            />
          </div>
          <pre>  </pre>
          <div style={{display: 'flex', flexDirection: 'column'}}>
            <div style={paddingStyle}>
              <SwapBinComponent isTrayPiece={isTrayPiece} enabled={running} />
            </div>
            <pre> </pre>
            <div>


              <div style={{
                overflow: 'auto',
                maxHeight: 100,
                borderStyle: 'solid',
                borderWidth: '3px',
                borderColor: 'DarkGrey',
                backgroundColor: 'Khaki',
                padding: '4px'
                }}>
                <ReactList
                  ref={c => this.wordReactListComponent = c}
                  itemRenderer={this.renderWord}
                  length={this.props.auxGameData.wordsPlayed.length}
                  type='uniform'
                />
              </div>



            </div>
          </div>
        </div>
        <pre>  </pre>
        <div>
          <label style={labelStyle}>{userName}: </label>
          <span style={{borderStyle: 'hidden', borderWidth: '5px'}}></span>
          <label style={fieldStyle}>{userScore}</label>
        </div>
        <div>
          <label style={labelStyle}>Bot: </label>
          <span style={{borderStyle: 'hidden', borderWidth: '5px'}}></span>
          <label style={fieldStyle}>{machineScore}</label>
        </div>
        <span style={{borderStyle: 'hidden', borderWidth: '5px'}}></span>
        <label style={fieldStyle}>{status}</label>
      </div>
    )
  }

});

export default DragDropContext(HTML5Backend)(GameComponent);

export {GameComponent as OriginalGameComponent}


