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
