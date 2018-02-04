
export const hasDragAndDrop = function() {
  let div = window.document.createElement('div');
  return ('draggable' in div) || ('ondragstart' in div && 'ondrop' in div);
};

export const isTouchDevice = ('ontouchstart' in window) || ((Navigator.maxTouchPoints in Navigator) && (Navigator.maxTouchPoints > 0));

export const isMobile = /Mobi/.test(navigator.userAgent);

