<template>
  <!-- All surveyed content is wrapped here; tracker attaches to this root div -->
  <div class="behavior-tracker-root" ref="root">
    <slot />
  </div>
</template>

<script>
import tracker from '@/lib/tracker';
import session from '@/lib/session';

const RESIZE_DEBOUNCE_MS = 150;

export default {
  name: 'BehaviorTracker',

  computed: {
    userShareUrl() {
      return session.getShareUrl();
    },
  },

  async mounted() {
    const userId = session.getUserId();
    if (!userId) return;

    tracker.start(userId);
    this.emitViewport();

    this._resizeTimer = null;
    this._onResize = () => {
      clearTimeout(this._resizeTimer);
      this._resizeTimer = setTimeout(() => this.emitViewport(), RESIZE_DEBOUNCE_MS);
    };
    window.addEventListener('resize', this._onResize);
  },

  beforeUnmount() {
    if (this._onResize) {
      window.removeEventListener('resize', this._onResize);
      clearTimeout(this._resizeTimer);
    }
    tracker.stop();
  },

  methods: {
    emitViewport() {
      const doc = document.documentElement;
      tracker.recordMetadata({
        type:             'viewport',
        innerWidth:       window.innerWidth,
        innerHeight:      window.innerHeight,
        devicePixelRatio: window.devicePixelRatio,
        scrollWidth:      doc.scrollWidth,
        scrollHeight:     doc.scrollHeight,
        screenWidth:      window.screen?.width ?? null,
        screenHeight:     window.screen?.height ?? null,
        userAgent:        navigator.userAgent,
      });
    },
  },
};
</script>

<style scoped>
.behavior-tracker-root {
  width: 100%;
  height: 100%;
}
</style>
