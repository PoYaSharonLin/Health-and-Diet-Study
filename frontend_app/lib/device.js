/**
 * device.js
 *
 * Input-capability device classifier. Used to keep mobile/tablet
 * respondents out of the survey flow before they are assigned a uid.
 *
 * Screen size alone can't tell a large tablet (iPad Pro, Samsung Tab)
 * apart from a laptop, and modern iPadOS Safari spoofs a "Macintosh"
 * user agent, so UA sniffing fails too. Instead we classify by pointer
 * capability: a desktop/laptop exposes at least one *fine* pointer
 * (mouse/trackpad), while a tablet/phone is touch-only.
 *
 * - A device with no fine pointer at all is treated as mobile/tablet.
 * - An iPad masquerading as macOS is caught via maxTouchPoints: real
 *   Macs report 0, iPads report > 1.
 * Touchscreen laptops keep a fine pointer, so they are still allowed.
 */

export function isMobileOrTablet() {
  const hasFinePointer = window.matchMedia('(any-pointer: fine)').matches;
  if (!hasFinePointer) return true;

  // iPadOS Safari spoofs a macOS UA but still reports touch points.
  const ua = navigator.userAgent;
  const isSpoofedIPad = /Macintosh/.test(ua) && navigator.maxTouchPoints > 1;
  if (isSpoofedIPad) return true;

  const uaSaysMobile = /Mobi|Android|iPhone|iPad|iPod/i.test(ua)
                    || navigator.userAgentData?.mobile === true;
  if (uaSaysMobile) return true;

  return false;
}
