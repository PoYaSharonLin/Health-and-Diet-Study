<template>
  <div v-if="show" class="lang-toggle" :aria-label="$t('langToggle.ariaLabel')">
    <button
      type="button"
      class="lang-btn"
      :class="{ active: $i18n.locale === 'zh' }"
      @click="pick('zh')"
    >{{ $t('langToggle.zh') }}</button>
    <button
      type="button"
      class="lang-btn"
      :class="{ active: $i18n.locale === 'en' }"
      @click="pick('en')"
    >{{ $t('langToggle.en') }}</button>
  </div>
</template>

<script>
import { IS_DEV, setLocale } from '@/lib/i18n';

export default {
  name: 'LangToggle',
  data() {
    return { show: IS_DEV };
  },
  methods: {
    pick(loc) {
      setLocale(loc);
    },
  },
};
</script>

<style scoped>
.lang-toggle {
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 10000;
  display: inline-flex;
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid #d6d6e0;
  border-radius: 999px;
  padding: 3px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  font-family: 'Inter', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.lang-btn {
  appearance: none;
  background: transparent;
  border: none;
  border-radius: 999px;
  padding: 5px 14px;
  font-size: 0.8rem;
  font-weight: 600;
  color: #6c63ff;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}

.lang-btn:hover:not(.active) {
  background: #f0f0ff;
}

.lang-btn.active {
  background: #6c63ff;
  color: #fff;
  box-shadow: 0 2px 8px rgba(108, 99, 255, 0.35);
}
</style>
