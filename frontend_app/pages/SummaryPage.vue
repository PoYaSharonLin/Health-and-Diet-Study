<template>
  <div class="survey-wrapper" data-track="page-background">
    <BehaviorTracker>
      <div class="survey-page">
        <header class="survey-header" data-track="page-header">
          <h1 class="survey-title">回答總覽</h1>
          <p class="survey-subtitle">請檢視您剛才的作答結果。</p>
        </header>

        <main v-if="userId && answers.length === questions.length" class="survey-body">
          <section class="score-section" data-track="page-score">
            <div class="score-label">總分</div>
            <div class="score-value">{{ totalScore }} <span class="score-range">/ 84</span></div>
            <div class="score-hint">分數區間 12–84，分數越高代表越健康的飲食行為</div>
          </section>

          <div
            v-for="(q, index) in questions"
            :key="index"
            class="summary-section"
            :data-track="'sq' + (index + 1) + '-element'"
          >
            <div class="question-label" :data-track="'sq' + (index + 1) + '-label'">
              ({{ index + 1 }}) {{ q.text }}
            </div>
            <div class="answer-row">
              <span class="answer-tag">你的答案</span>
              <span class="answer-value">{{ answers[index] }}</span>
              <span class="answer-scale">/ 7</span>
            </div>
            <div class="label-row">
              <span class="label-cell label-min">1 = {{ q.minLabel }}</span>
              <span class="label-sep">↔</span>
              <span class="label-cell label-max">7 = {{ q.maxLabel }}</span>
            </div>
          </div>

          <div class="submit-row">
            <button
              class="submit-btn"
              data-track="summary-next"
              @click="goNext"
            >
              下一頁
            </button>
          </div>
        </main>

        <div v-else class="no-uid-notice">
          <p>找不到問卷作答紀錄，請從頭開始。</p>
        </div>
      </div>
    </BehaviorTracker>
  </div>
</template>

<script>
import BehaviorTracker from '@/components/BehaviorTracker.vue';
import session         from '@/lib/session';

export default {
  name: 'SummaryPage',

  components: { BehaviorTracker },

  data() {
    return {
      userId:  null,
      answers: [],
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
    };
  },

  async created() {
    this.userId = await session.init();
    const raw = sessionStorage.getItem('survey_answers_v1');
    if (raw) {
      try {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed.dietary)) this.answers = parsed.dietary;
      } catch (_) { /* ignore malformed data */ }
    }
  },

  computed: {
    totalScore() {
      return this.answers.reduce((sum, v) => sum + (Number(v) || 0), 0);
    },
  },

  methods: {
    goNext() {
      const uid   = this.userId;
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/postsurvey${query}`);
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

.survey-body {
  padding: 40px;
}

.score-section {
  text-align: center;
  margin-bottom: 32px;
  padding: 28px 24px;
  background: linear-gradient(135deg, #f0f0ff 0%, #eef7ff 100%);
  border-radius: 14px;
  border: 1px solid #e0dfff;
}

.score-label {
  font-size: 0.95rem;
  color: #6c63ff;
  font-weight: 600;
  letter-spacing: 1px;
}

.score-value {
  font-size: 3rem;
  font-weight: 900;
  color: #4a42d6;
  margin: 4px 0 8px;
}

.score-range {
  font-size: 1.4rem;
  font-weight: 600;
  color: #999;
}

.score-hint {
  font-size: 0.85rem;
  color: #777;
}

.summary-section {
  margin-bottom: 20px;
  padding: 20px 24px;
  border: 1px solid #f0f0f0;
  border-radius: 12px;
  background: #fafafa;
}

.question-label {
  display: block;
  font-size: 1rem;
  font-weight: 600;
  color: #333;
  margin-bottom: 12px;
  line-height: 1.5;
}

.answer-row {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 10px;
}

.answer-tag {
  font-size: 0.8rem;
  color: #6c63ff;
  background: #eeebff;
  padding: 2px 10px;
  border-radius: 999px;
  font-weight: 600;
}

.answer-value {
  font-size: 1.6rem;
  font-weight: 800;
  color: #4a42d6;
}

.answer-scale {
  font-size: 1rem;
  color: #aaa;
  font-weight: 500;
}

.label-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.78rem;
  color: #888;
  line-height: 1.5;
}

.label-cell {
  flex: 1;
}

.label-min { text-align: left; }
.label-max { text-align: right; }
.label-sep { color: #ccc; }

.submit-row {
  text-align: center;
  margin-top: 40px;
  margin-bottom: 16px;
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

.submit-btn:hover {
  background-color: #5a52e0;
  transform: translateY(-2px);
  box-shadow: 0 6px 24px rgba(108, 99, 255, 0.35);
}

.no-uid-notice {
  padding: 80px 40px;
  text-align: center;
  color: #888;
}
</style>
