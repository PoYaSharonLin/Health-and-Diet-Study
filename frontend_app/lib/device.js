/**
 * device.js
 *
 * Viewport-based device classifier. Used to keep mobile/tablet
 * respondents out of the survey flow before they are assigned a uid.
 *
 * Rule: a device is treated as desktop only when the short side is
 * at least 700 px and the long side is at least 1000 px.
 */

const MIN_SHORT_SIDE = 700;
const MIN_LONG_SIDE  = 1000;

export function isMobileOrTablet() {
  const w = window.innerWidth;
  const h = window.innerHeight;
  const short = Math.min(w, h);
  const long  = Math.max(w, h);
  return short < MIN_SHORT_SIDE || long < MIN_LONG_SIDE;
}
