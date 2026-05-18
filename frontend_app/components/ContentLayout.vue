<template>
  <div class="content-wrapper" data-track="page-background">
    <BehaviorTracker>
      <div class="content-page">
        <header class="content-header" data-track="page-header">
          <h1 class="content-title">{{ title }}</h1>
        </header>
        <main v-if="userId" class="content-body">
          <slot />
          <div class="next-row">
            <button
              class="next-btn"
              :class="{ active: canAdvance }"
              :disabled="!canAdvance"
              data-track="page-next"
              @click="$emit('next')"
            >
              {{ nextLabel || $t('common.next') }}
            </button>
          </div>
          <p v-if="hint" class="hint">{{ hint }}</p>
        </main>
        <div v-else class="no-uid-notice">
          <p>{{ $t('common.uidMissing') }}</p>
        </div>
      </div>
    </BehaviorTracker>
  </div>
</template>

<script>
import BehaviorTracker from '@/components/BehaviorTracker.vue';
import session from '@/lib/session';

export default {
  name: 'ContentLayout',
  components: { BehaviorTracker },
  props: {
    title:      { type: String,  required: true },
    canAdvance: { type: Boolean, default: true },
    nextLabel:  { type: String,  default: '' },
    hint:       { type: String,  default: '' },
  },
  emits: ['next'],
  data() {
    return { userId: null };
  },
  async created() {
    this.userId = await session.init();
  },
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;900&display=swap');

* { box-sizing: border-box; }

.content-wrapper {
  min-height: 100vh;
  width: 100%;
  background: #f4f7f6;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  padding: 48px 16px 80px;
  font-family: 'Inter', sans-serif;
}

.content-page {
  width: 100%;
  max-width: 800px;
  margin: 0 auto;
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 8px 48px rgba(108, 99, 255, 0.12);
  overflow: hidden;
}

.content-header {
  background: #6c63ff;
  padding: 40px 40px 32px;
  color: #fff;
  text-align: center;
}

.content-title {
  font-size: 1.6rem;
  font-weight: 900;
  margin: 0;
  letter-spacing: -0.3px;
  line-height: 1.35;
}

.content-body {
  padding: 40px;
  color: #333;
  line-height: 1.7;
  font-size: 1rem;
}

.next-row {
  margin-top: 40px;
  display: flex;
  justify-content: flex-end;
}

.next-btn {
  padding: 12px 32px;
  font-size: 1rem;
  font-weight: 600;
  background: #ccc;
  color: #fff;
  border: none;
  border-radius: 8px;
  cursor: not-allowed;
  transition: background 0.2s, box-shadow 0.2s;
}

.next-btn.active {
  background: #6c63ff;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
}

.next-btn.active:hover { background: #5a52d5; }

.hint {
  margin-top: 8px;
  text-align: right;
  color: #e57373;
  font-size: 0.85rem;
}

.no-uid-notice {
  padding: 80px 40px;
  text-align: center;
  color: #888;
}
</style>
