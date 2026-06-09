<template>
  <div class="practice-wrapper">
    <div class="practice-page">
        <header class="practice-header">
          <h1 class="practice-title">{{ $t('practice.title') }}</h1>
        </header>

        <main class="practice-body" v-if="userId">
          <component :is="variantComponent" v-if="variantComponent" />

          <div class="practice-section" data-track="practice-q1-element">
            <label class="question-label">{{ $t('practice.question') }}</label>
            <div class="slider-container">
              <SliderBar
                v-model="answer"
                track-prefix="practice-q1"
                :min="0"
                :max="9"
                :step="1"
                :minLabel="$t('practice.minLabel')"
                :maxLabel="$t('practice.maxLabel')"
                :finished="confirmed"
                @interact="onSliderChange"
                @change="onSliderChange"
              />
            </div>
            <div class="confirm-container">
              <button
                class="confirm-btn"
                :class="{ confirmed, disabled: !sliderMoved }"
                @click="confirm"
                data-track="practice-q1-confirm"
                :disabled="!sliderMoved || confirmed"
                :title="confirmTitle"
              >
                <span class="icon">✓</span>
              </button>
            </div>
          </div>

          <section class="please-note" data-track="practice-please-note">
            <div class="please-note-header">
              <svg class="warning-icon" viewBox="0 0 64 60" aria-hidden="true">
                <path d="M32 4 C 34 4 35.5 5 36.5 6.8 L 60 50 C 61 52 60.5 54.5 59 55.5 C 58 56 57 56 56 56 L 8 56 C 6 56 4.5 55 4 53.5 C 3.5 52 3.8 50.5 4 50 L 27.5 6.8 C 28.5 5 30 4 32 4 Z" fill="#F5C518"/>
                <rect x="29" y="20" width="6" height="20" rx="3" fill="#1a1a1a"/>
                <circle cx="32" cy="46" r="3.5" fill="#1a1a1a"/>
              </svg>
              <h2 class="please-note-title">{{ $t('practice.pleaseNote.title') }}</h2>
            </div>
            <div class="please-note-body">
              <i18n-t keypath="practice.pleaseNote.lead" tag="p" class="please-note-lead" scope="global">
                <template #strong><strong>{{ $t('practice.pleaseNote.leadStrong') }}</strong></template>
              </i18n-t>
              <p class="please-note-points-header">{{ $t('practice.pleaseNote.pointsHeader') }}</p>
              <ol class="please-note-points">
                <li>{{ $t('practice.pleaseNote.point1') }}</li>
                <li>{{ $t('practice.pleaseNote.point2') }}</li>
                <li>{{ $t('practice.pleaseNote.point3') }}</li>
              </ol>
              <p class="please-note-closing">{{ $t('practice.pleaseNote.closing') }}</p>
            </div>
          </section>

          <div class="next-container">
            <button
              class="next-btn"
              :class="{ active: confirmed }"
              @click="goNext"
              :disabled="!confirmed"
              data-track="practice-next"
            >
              {{ $t('common.next') }}
            </button>
          </div>
        </main>

        <div v-else class="no-uid-notice">
          <p>{{ $t('common.uidMissing') }}</p>
        </div>
    </div>
  </div>
</template>

<script>
import SliderBar from '@/components/SliderBar.vue';
import session   from '@/lib/session';
import PracticeWoEOWoRAM from '@/components/practice/PracticeWoEOWoRAM.vue';
import PracticeWEOWoRAM  from '@/components/practice/PracticeWEOWoRAM.vue';
import PracticeWoEOWRAM  from '@/components/practice/PracticeWoEOWRAM.vue';
import PracticeWEOWRAM   from '@/components/practice/PracticeWEOWRAM.vue';

const VARIANT_BY_CONDITION = {
  'woEO-woRAM': PracticeWoEOWoRAM,
  'wEO-woRAM':  PracticeWEOWoRAM,
  'woEO-wRAM':  PracticeWoEOWRAM,
  'wEO-wRAM':   PracticeWEOWRAM,
};

export default {
  name: 'PracticePage',
  components: { SliderBar },

  data() {
    const flags = session.resolveFlags();
    const sliderDefault = flags?.hasRAM ? 0 : 9;
    return {
      userId:      null,
      answer:      sliderDefault,
      confirmed:   false,
      sliderMoved: false,
    };
  },

  async created() {
    this.userId = await session.init();
  },

  computed: {
    variantComponent() {
      const flags = session.getFlags();
      return flags ? VARIANT_BY_CONDITION[flags.condition] || null : null;
    },
    confirmTitle() {
      if (this.confirmed) return this.$t('common.confirmTitle.confirmed');
      if (!this.sliderMoved) return this.$t('common.confirmTitle.notTouched');
      return this.$t('common.confirmTitle.ready');
    },
  },

  methods: {
    onSliderChange() {
      this.sliderMoved = true;
    },

    confirm() {
      if (this.confirmed || !this.sliderMoved) return;
      this.confirmed = true;
      sessionStorage.setItem('practice_done', '1');
    },

    goNext() {
      if (!this.confirmed) return;
      const uid   = session.getUserId();
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/susceptibility${query}`);
    },
  },
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;900&display=swap');

* { box-sizing: border-box; }

.practice-wrapper {
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

.practice-page {
  width: 100%;
  max-width: 800px;
  margin: 0 auto;
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 8px 48px rgba(108, 99, 255, 0.12);
  overflow: hidden;
}

.practice-header {
  background: #6c63ff;
  padding: 40px 40px 32px;
  color: #fff;
  text-align: center;
}

.practice-title {
  font-size: 1.8rem;
  font-weight: 900;
  margin: 0;
  letter-spacing: -0.5px;
}

.practice-body {
  padding: 40px;
}

.practice-section {
  padding: 24px;
  border: 1px solid #f0f0f0;
  border-radius: 12px;
  background: #fafafa;
}

.question-label {
  display: block;
  font-size: 1rem;
  font-weight: 600;
  color: #333;
  margin-bottom: 20px;
  line-height: 1.5;
}

.slider-container { flex: 1; }

.confirm-container {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}

.confirm-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  background: #fff;
  color: #6c63ff;
  border: 1.5px solid #6c63ff;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.confirm-btn:hover { background: #f0f0ff; }

.confirm-btn.confirmed {
  background: #4caf50;
  color: #fff;
  border-color: #4caf50;
  box-shadow: 0 4px 12px rgba(76, 175, 80, 0.3);
}

.confirm-btn .icon { font-size: 1.1rem; }

.confirm-btn.disabled,
.confirm-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.please-note {
  margin-top: 32px;
  padding: 32px 28px;
  background: #fafafa;
  border: 1px solid #f0f0f0;
  border-radius: 12px;
}

.please-note-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 36px;
  padding-bottom: 28px;
  border-bottom: 1px dashed #e0e0e0;
}

.warning-icon {
  width: 96px;
  height: 96px;
  flex-shrink: 0;
}

.please-note-title {
  margin: 0;
  font-size: 1.8rem;
  font-weight: 700;
  color: #e53935;
  letter-spacing: 0.04em;
}

.please-note-body {
  padding-top: 24px;
  font-size: 0.98rem;
  line-height: 1.85;
  color: #333;
  text-align: left;
}

.please-note-lead {
  margin: 0 0 16px;
}

.please-note-lead :deep(strong) {
  font-weight: 700;
  color: #222;
}

.please-note-points-header {
  margin: 0 0 8px;
}

.please-note-points {
  margin: 0 0 20px;
  padding-left: 1.6em;
  font-weight: 700;
  color: #222;
}

.please-note-points li {
  margin-bottom: 6px;
}

.please-note-closing {
  margin: 24px 0 0;
}

@media (max-width: 560px) {
  .please-note { padding: 24px 18px; }
  .please-note-header { gap: 20px; padding-bottom: 20px; }
  .warning-icon { width: 72px; height: 72px; }
  .please-note-title { font-size: 1.5rem; }
}

.next-container {
  margin-top: 32px;
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

.next-btn.active:hover {
  background: #5a52d5;
}

.no-uid-notice {
  padding: 80px 40px;
  text-align: center;
  color: #888;
}
</style>
