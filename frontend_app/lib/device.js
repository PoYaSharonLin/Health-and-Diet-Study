/**
 * device.js
 *
 * Screen-based device classifier. Used to keep mobile/tablet
 * respondents out of the survey flow before they are assigned a uid.
 *
 * Rule: a device is treated as desktop only when the screen's short
 * side is at least 600 px and the long side is at least 1000 px.
 * Uses screen.* (physical monitor) instead of innerWidth/Height so
 * split-window users on real desktops aren't falsely blocked.
 */

const MIN_SHORT_SIDE = 600;
const MIN_LONG_SIDE  = 1000;

export function isMobileOrTablet() {
  const w = window.screen.width;
  const h = window.screen.height;
  const short = Math.min(w, h);
  const long  = Math.max(w, h);
  if (short < MIN_SHORT_SIDE || long < MIN_LONG_SIDE) return true;

  const ua = navigator.userAgent;
  const uaSaysMobile = /Mobi|Android|iPhone|iPad|iPod/i.test(ua)
                    || navigator.userAgentData?.mobile === true;
  const noFinePointer = !window.matchMedia('(pointer: fine)').matches;
  if (uaSaysMobile && noFinePointer) return true;

  return false;
}
