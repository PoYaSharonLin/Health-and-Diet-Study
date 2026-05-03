<template>
  <div class="survey-wrapper" data-track="page-background">
    <BehaviorTracker>
      <div class="survey-page">
        <!-- Header -->
        <header class="survey-header" data-track="page-header">
          <h1 class="survey-title">飲食行為問卷</h1>
          <p class="survey-subtitle warning" v-if="!userId">
            ⚠ 未找到使用者 ID。請使用提供的連結進入此頁面。
          </p>
        </header>

        <!-- Survey body -->
        <main v-if="userId" class="survey-body">
          <section class="intro-section" data-track="page-intro">
            <h2>過去一週的飲食回報</h2>
            <p>請根據您對以下敘述的同意程度，使用滑桿作答（1 為最低，7 為最高）。</p>
          </section>

          <div v-for="(q, index) in questions" :key="index" class="survey-section" :data-track="'q' + (index + 1) + '-element'">
            <label class="question-label" :data-track="'q' + (index + 1) + '-label'">({{ index + 1 }}) {{ q.text }} *</label>
            <!-- Slider Container -->
            <div class="slider-container">
              <SliderBar
                v-model="answers.dietary[index]"
                :track-prefix="'q' + (index + 1)"
                :min="1"
                :max="7"
                :step="1"
                :minLabel="q.minLabel"
                :maxLabel="q.maxLabel"
                :finished="confirmedQuestions[index]"
              />
            </div>
            <!-- Confirm Button (Icon only) -->
            <div class="confirm-container">
              <button
                class="confirm-btn"
                :class="{ confirmed: confirmedQuestions[index] }"
                @click="toggleConfirm(index)"
                :data-track="'q' + (index + 1) + '-confirm'"
                :title="confirmedQuestions[index] ? '已確認' : '確認答案'"
              >
                <span class="icon">✓</span>
              </button>
            </div>
          </div>

          <!-- Next -->
          <div class="submit-row">
            <p v-if="!allConfirmed" class="validation-hint">
              請確認所有題目後再繼續（已確認 {{ confirmedCount }}/{{ questions.length }} 題）
            </p>
            <button
              class="submit-btn"
              data-track="survey-next"
              :disabled="!allConfirmed"
              @click="goNext"
            >
              下一頁
            </button>
          </div>
        </main>

        <!-- No UID state -->
        <div v-else class="no-uid-notice">
          <p>請重新開啟包含 <code>?uid=…</code> 參數的連結。</p>
        </div>
      </div>
    </BehaviorTracker>
  </div>
</template>

<script>
import BehaviorTracker from '@/components/BehaviorTracker.vue';
import SliderBar       from '@/components/SliderBar.vue';
import session         from '@/lib/session';

export default {
  name: 'SurveyPage',

  components: { BehaviorTracker, SliderBar },

  data() {
    return {
      userId:    null,
      questions: [
        { text: '過去一週你有規律地吃三餐嗎？', minLabel: '我這七天從未規律地吃三餐', maxLabel: '我這七天都規律地吃三餐' },
        { text: '過去一週你有吃糖果或是零食嗎？', minLabel: '我這七天都有吃糖果或零食', maxLabel: '我這七天從未吃糖果或零食' },
        { text: '過去一週你有充分咀嚼食物，每一口至少咀嚼二十次後才吞嚥嗎？', minLabel: '我這七天從未充分咀嚼食物就吞嚥', maxLabel: '我這七天每一口都至少咀嚼二十次' },
        { text: '過去一週在口渴或炎熱時，你除了喝白開水外，有喝不健康飲品嗎(含糖或含酒精)?', minLabel: '我這七天都有喝不健康的飲品', maxLabel: '我這七天都只喝白開水' },
        { text: '過去一週你有吃油炸或油膩的食物（如花生、薯片、炸雞等）嗎？', minLabel: '我這七天都吃油炸的食物', maxLabel: '我這七天從未吃油炸的食物' },
        { text: '過去一週你每天都有吃水果嗎？', minLabel: '我這七天從未吃水果', maxLabel: '我這七天都有吃水果' },
        { text: '過去一週你每天都有吃綠色蔬菜嗎？', minLabel: '我這七天從未吃綠色蔬菜', maxLabel: '我這七天都有吃綠色蔬菜' },
        { text: '過去一週你每天都有吃宵夜嗎?', minLabel: '我這七天都有吃宵夜', maxLabel: '我這七天從未吃宵夜' },
        { text: '過去一週你有一邊看電視或用平板、手機、電腦一邊吃東西嗎？', minLabel: '我這七天吃東西時都會分心', maxLabel: '我這七天都會專心吃東西' },
        { text: '過去一週你心情不好時，會透過吃東西讓心情變好嗎？', minLabel: '我這七天都會透過吃東西讓心情變好', maxLabel: '我這七天從未透過吃東西讓心情變好' },
        { text: '過去一週你會把吃東西當作獎勵自己或是慶祝的方式嗎？', minLabel: '我這七天都用吃東西獎勵自己', maxLabel: '我這七天從未用吃東西獎勵自己' },
        { text: '過去一週你會在非常飢餓的時候，才去賣場採購食物嗎？', minLabel: '我這七天都等到非常餓才採購食物', maxLabel: '我這七天從未等到非常餓才採購食物' },
      ],
      answers: {
        dietary: Array(12).fill(1),
      },
      confirmedQuestions: Array(12).fill(false),
    };
  },

  async created() {
    this.userId = await session.init();
    const saved = localStorage.getItem('survey_answers_draft');
    if (saved) {
      try {
        const { dietary, confirmed } = JSON.parse(saved);
        if (Array.isArray(dietary) && dietary.length === this.answers.dietary.length) {
          this.answers.dietary = dietary;
        }
        if (Array.isArray(confirmed) && confirmed.length === this.confirmedQuestions.length) {
          this.confirmedQuestions = confirmed;
        }
      } catch (_) { /* ignore malformed data */ }
    }
  },

  watch: {
    answers: {
      deep: true,
      handler(val) {
        localStorage.setItem('survey_answers_draft', JSON.stringify({
          dietary:   val.dietary,
          confirmed: this.confirmedQuestions,
        }));
      },
    },
    confirmedQuestions: {
      deep: true,
      handler(val) {
        localStorage.setItem('survey_answers_draft', JSON.stringify({
          dietary:   this.answers.dietary,
          confirmed: val,
        }));
      },
    },
  },

  computed: {
    confirmedCount() {
      return this.confirmedQuestions.filter(Boolean).length;
    },
    allConfirmed() {
      return this.confirmedQuestions.every(Boolean);
    },
  },

  methods: {
    goNext() {
      if (!this.allConfirmed) return;
      sessionStorage.setItem('survey_answers_v1', JSON.stringify({
        dietary: this.answers.dietary,
      }));
      localStorage.removeItem('survey_answers_draft');
      const uid   = this.userId;
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/summary${query}`);
    },
    toggleConfirm(index) {
      this.confirmedQuestions[index] = !this.confirmedQuestions[index];
    },
  },
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;900&display=swap');

* { box-sizing: border-box; }

.survey-wrapper {
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

.survey-page {
  width: 100%;
  max-width: 800px;
  margin: 0 auto;
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 8px 48px rgba(108, 99, 255, 0.12);
  overflow: hidden;
}

/* ── Header ──────────────────────────────────────────────── */
.survey-header {
  background: #6c63ff;
  padding: 40px 40px 32px;
  color: #fff;
  text-align: center;
}

.survey-title {
  font-size: 1.8rem;
  font-weight: 900;
  margin: 0 0 8px;
  letter-spacing: -0.5px;
}

.survey-subtitle {
  margin: 0;
  font-size: 0.9rem;
  opacity: 0.85;
}

.survey-subtitle.warning { color: #ffe082; }

.uid-tag {
  background: rgba(255,255,255,0.2);
  padding: 2px 8px;
  border-radius: 4px;
  font-family: monospace;
}

/* ── Body ───────────────────────────────────────────────── */
.survey-body {
  padding: 40px;
}

.intro-section {
  margin-bottom: 32px;
  text-align: center;
}

.intro-section h2 {
  font-size: 1.4rem;
  font-weight: 700;
  color: #333;
  margin-bottom: 12px;
}

.intro-section p {
  color: #666;
  line-height: 1.6;
}

.survey-section {
  margin-bottom: 32px;
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

.question-container {
  display: flex;
  align-items: flex-start;
  gap: 1.5rem;
}

.progress-svg {
  flex-shrink: 0;
  margin-top: 0.5rem;
}

.slider-container {
  flex: 1;
}

.optional {
  font-weight: 400;
  color: #aaa;
  font-size: 0.85rem;
}

.feedback-textarea {
  width: 100%;
  border: 1.5px solid #e0e0e0;
  border-radius: 10px;
  padding: 14px;
  font-size: 0.95rem;
  font-family: inherit;
  resize: vertical;
  transition: border-color 0.2s;
  outline: none;
  color: #333;
}

.feedback-textarea:focus {
  border-color: #6c63ff;
  box-shadow: 0 0 0 3px rgba(108,99,255,0.15);
}

/* ── Confirm Button ── */
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

.confirm-btn:hover {
  background: #f0f0ff;
}

.confirm-btn.confirmed {
  background: #4caf50;
  color: #fff;
  border-color: #4caf50;
  box-shadow: 0 4px 12px rgba(76, 175, 80, 0.3);
}

.confirm-btn .icon {
  font-size: 1.1rem;
}

/* ── Submit ─────────────────────────────────────────────── */
.submit-row {
  text-align: center;
  margin-top: 48px;
  margin-bottom: 32px;
}

.submit-btn {
  background: #6c63ff;
  color: #fff;
  border: none;
  border-radius: 50px;
  padding: 16px 64px;
  font-size: 1.1rem;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.15s, box-shadow 0.15s, background-color 0.2s;
}

.submit-btn:hover:not(:disabled) {
  background-color: #5a52e0; /* Slightly darker indigo */
  transform: translateY(-2px);
  box-shadow: 0 6px 24px rgba(108, 99, 255, 0.35);
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: default;
}

.validation-hint {
  margin-bottom: 12px;
  color: #e57373;
  font-size: 0.9rem;
  font-weight: 500;
}

.no-uid-notice {
  padding: 80px 40px;
  text-align: center;
  color: #888;
}
</style>
