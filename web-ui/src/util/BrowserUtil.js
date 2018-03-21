/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import detectIt from 'detect-it';
import {queryParams} from './UrlUtil';

let mouse = 'mouse';
let touch = 'touch';

export const INPUT_DEVICES = [mouse, touch];

export const hasDragAndDrop = function() {
  let div = window.document.createElement('div');
  return ('draggable' in div) || ('ondragstart' in div && 'ondrop' in div);
};

// Obsolete legacy checks.
// export const isTouchDevice = ('ontouchstart' in window) || ((Navigator.maxTouchPoints in Navigator) && (Navigator.maxTouchPoints > 0));
// export const isMobile = /Mobi/.test(navigator.userAgent);

export const usingMouse = function() {
  let preferred = getPreferredInputDevice();
  let inputDevice = pointingDevice(preferred);
  return inputDevice === mouse;
};

export const usingTouch = function() {
  let preferred = getPreferredInputDevice();
  let inputDevice = pointingDevice(preferred);
  return inputDevice === touch;
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

const getPreferredInputDevice = function() {
  // TODO. Constant used also in index.js. Should be defined in GameParams.
  return queryParams(window.location).getParam("preferred-input-device");
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
function detectPrimaryDevice() {
  let primary = detectIt.primaryInput;
  if (primary === mouse || primary === touch)
    return primary;
  if (detectIt.hasMouse)
    return 'mouse';
  if (detectIt.hasTouch)
    return 'touch';
  return undefined;
}
