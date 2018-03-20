/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import detectIt from 'detect-it';

let mouse = 'mouse';
let touch = 'touch';

export const InputDevice = {
  mouse: mouse,
  touch: touch
};

export const INPUT_DEVICES = [mouse, touch];

export const hasDragAndDrop = function() {
  let div = window.document.createElement('div');
  return ('draggable' in div) || ('ondragstart' in div && 'ondrop' in div);
};

// export const isTouchDevice = ('ontouchstart' in window) || ((Navigator.maxTouchPoints in Navigator) && (Navigator.maxTouchPoints > 0));

let inputDevice = undefined;

export const usingMouse = function() {
  return inputDevice === mouse;
};

export const usingTouch = function() {
  return inputDevice === touch;
};

export const isMobile = /Mobi/.test(navigator.userAgent);


/**
 * Initialize browser information based in part on user preferences.
 * Must be called before components are created. Not ideal.
 * Top-level React DND components (in our case GameComponent) need a backend
 * (basically an input device driver for mouse vs touch) for drag and drop.
 * But the choice of device may depend on user preferences revealed only
 * at application initiation. I don't yet know of a way of creating these
 * components via functions that take the device type as a parameter.
 * The best I can do so far is to set the device in this module, and then
 * use it in creating the GameComponent.
 */
export const initBrowserInfo = function(preferredDevice, inputDevices) {
  inputDevice = pointingDevice(preferredDevice, inputDevices);
};

export const getInputDevice = function() {
  return inputDevice;
};

/**
 * Get the name of the pointing device to use.
 * @param preferredDevice The user's preferred device ('mouse' or 'touch') -
 *    returned if available in current browser.
 * @returns 'mouse' or 'touch' or undefined.
 */
export const pointingDevice = function(preferredDevice) {
  if (isDeviceAvailable(preferredDevice))
    return preferredDevice;
  return detectPrimaryDevice();
};

function isDeviceAvailable(deviceName) {
  if (deviceName === undefined)
    return false;

  switch (deviceName) {
    case mouse:
      return (detectIt.hasMouse = true) || (detectIt.primaryInput === mouse);
    case touch:
      return (detectIt.hasTouch = true) || (detectIt.primaryInput === touch);
    default:
      return false;
  }
}

/**
 * If no primary input is detectable then default to mouse if available,
 * otherwise to touch if available.
 */
function detectPrimaryDevice(inputDevices) {
  let primary = detectIt.primaryInput;
  if (primary === mouse || primary === touch)
    return primary;
  if (detectIt.hasMouse)
    return 'mouse';
  if (detectIt.hasTouch)
    return 'touch';
  return undefined;
}
