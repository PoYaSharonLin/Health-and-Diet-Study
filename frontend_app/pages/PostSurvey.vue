<template>
  <div class="survey-wrapper" data-track="page-background">
    <BehaviorTracker>
      <div class="survey-page">
        <header class="survey-header" data-track="page-header">
          <h1 class="survey-title">後測問卷</h1>
          <p class="survey-subtitle warning" v-if="!userId">
            ⚠ 未找到使用者 ID。請使用提供的連結進入此頁面。
          </p>
        </header>

        <main v-if="userId" class="survey-body">
          <section class="intro-section" data-track="page-intro">
            <h2>最後幾個問題</h2>
            <p>請根據您的感受，使用滑桿作答（1 為最低，7 為最高）。</p>
          </section>

          <div v-for="(q, index) in questions" :key="index" class="survey-section" :data-track="'pq' + (index + 1) + '-element'">
            <label class="question-label" :data-track="'pq' + (index + 1) + '-label'">({{ index + 1 }}) {{ q.text }} *</label>
            <div class="slider-container">
              <SliderBar
                v-model="answers[index]"
                :track-prefix="'pq' + (index + 1)"
                :min="1"
                :max="7"
                :step="1"
                :minLabel="q.minLabel"
                :maxLabel="q.maxLabel"
                :finished="confirmedQuestions[index]"
              />
            </div>
            <div class="confirm-container">
              <button
                class="confirm-btn"
                :class="{ confirmed: confirmedQuestions[index] }"
                @click="toggleConfirm(index)"
                :data-track="'pq' + (index + 1) + '-confirm'"
                :title="confirmedQuestions[index] ? '已確認' : '確認答案'"
              >
                <span class="icon">✓</span>
              </button>
            </div>
          </div>

          <div class="submit-row">
            <p v-if="!allConfirmed && !submitted" class="validation-hint">
              請確認所有題目後再提交（已確認 {{ confirmedCount }}/{{ questions.length }} 題）
            </p>
            <button
              class="submit-btn"
              data-track="postsurvey-submit"
              :disabled="submitting || submitted || !allConfirmed"
              @click="submit"
            >
              前往最後一份問卷
            </button>
            <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
          </div>
        </main>

        <div v-else class="no-uid-notice">
          <p>請重新開啟包含 <code>?uid=…</code> 參數的連結。</p>
        </div>
      </div>
    </BehaviorTracker>

    <!-- Spinner overlay -->
    <div v-if="submitting" class="spinner-overlay">
      <div class="spinner"></div>
      <p class="spinner-text">資料上傳中，請稍候…</p>
    </div>
  </div>
</template>

<script>
import BehaviorTracker from '@/components/BehaviorTracker.vue';
import SliderBar       from '@/components/SliderBar.vue';
import session         from '@/lib/session';
import tracker         from '@/lib/tracker';

export default {
  name: 'PostSurvey',

  components: { BehaviorTracker, SliderBar },

  data() {
    return {
      userId:     null,
      submitting: false,
      submitted:  false,
      errorMsg:   '',
      questions: [
        { text: '你的好友在回答這份問卷時多有可能謊報？',   minLabel: '非常可能謊報', maxLabel: '非常不可能謊報' },
        { text: '一般受測者在回答這份問卷時多有可能謊報？', minLabel: '非常可能謊報', maxLabel: '非常不可能謊報' },
        { text: '你剛才在回答這份問卷時多有可能謊報？',     minLabel: '非常可能謊報', maxLabel: '非常不可能謊報' },
      ],
      answers: Array(3).fill(1),
      confirmedQuestions: Array(3).fill(false),
    };
  },

  async created() {
    this.userId = await session.init();
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
    toggleConfirm(index) {
      this.confirmedQuestions[index] = !this.confirmedQuestions[index];
    },

    async submit() {
      if (this.submitting || this.submitted || !this.allConfirmed) return;
      this.errorMsg   = '';
      this.submitting = true;

      const startedAt = Date.now();
      const minSpinnerMs = 1000;

      try {
        const surveyRaw = sessionStorage.getItem('survey_answers_v1');
        const surveyAnswers = surveyRaw ? JSON.parse(surveyRaw) : {};

        // 1. Save combined answers to session metadata
        await import('axios').then(({ default: axios }) =>
          axios.post('/api/survey/session', {
            respondent_id: this.userId,
            metadata: {
              answers:      surveyAnswers.dietary || [],
              post_answers: this.answers,
              submitted_at: new Date().toISOString(),
            },
          })
        );

        // 2. Presigned URL
        const presignRes = await fetch(
          `/api/behavior/${encodeURIComponent(this.userId)}/presigned-url`
        );
        if (!presignRes.ok) {
          throw new Error(`presigned-url failed: ${presignRes.status}`);
        }
        const { url, key, expires_at } = await presignRes.json();
        console.log('[presigned-url] url:', url, '| key:', key, '| expires_at:', expires_at);

        // 3. PUT blob to S3
        const buffer = tracker.getBinaryBlob();
        const s3Res = await fetch(url, {
          method:  'PUT',
          headers: { 'Content-Type': 'application/octet-stream' },
          body:    buffer,
        });
        if (!s3Res.ok) {
          throw new Error(`S3 PUT failed: ${s3Res.status}`);
        }
        console.log('[confirm-upload] Confirm upload from S3 ✓');

        // 4. Confirm upload to backend
        const confirmRes = await fetch(
          `/api/behavior/${encodeURIComponent(this.userId)}/confirm-upload`,
          {
            method:  'POST',
            headers: { 'Content-Type': 'application/json' },
            body:    JSON.stringify({ key }),
          }
        );
        if (!confirmRes.ok) {
          throw new Error(`confirm-upload failed: ${confirmRes.status}`);
        }
        console.log('[confirm-upload] Confirm write-in in database ✓');
        tracker.clearPersistedHistory();

        // 5. Verify downloadable
        const downloadRes = await fetch(
          `/api/behavior/${encodeURIComponent(this.userId)}/download-url`
        );
        if (!downloadRes.ok) {
          throw new Error(`download-url failed: ${downloadRes.status}`);
        }
        const { url: downloadUrl, expires_at: downloadExpiresAt } = await downloadRes.json();
        console.log('[download-url] Get request successful ✓ | url:', downloadUrl, '| expires_at:', downloadExpiresAt);

        const dataRes = await fetch(downloadUrl, { method: 'GET' });
        if (dataRes.ok || dataRes.status === 206) {
          console.log('[download-url] Download data successfully ✓');
        } else {
          console.error('[download-url] Object fetch failed:', dataRes.status);
        }

        // Ensure spinner shows at least 1s
        const elapsed = Date.now() - startedAt;
        if (elapsed < minSpinnerMs) {
          await new Promise(r => setTimeout(r, minSpinnerMs - elapsed));
        }

        this.submitted = true;

        const moonbearUrl = new URL(
          'https://moonbear.herokuapp.com/onlinesurvey/f922a475-4ef3-4d3a-992d-996b507f732c/d4dbab7c-c7c9-43c4-819f-27494691bb91'
        );
        moonbearUrl.searchParams.set('uid', this.userId);
        const condition = session.getCondition();
        if (condition) moonbearUrl.searchParams.set('condition', condition);
        window.location.href = moonbearUrl.toString();
      } catch (err) {
        console.error('[postsurvey submit] error:', err);
        const elapsed = Date.now() - startedAt;
        if (elapsed < minSpinnerMs) {
          await new Promise(r => setTimeout(r, minSpinnerMs - elapsed));
        }
        this.errorMsg = '上傳失敗，請點擊「提交問卷」重試。';
      } finally {
        this.submitting = false;
      }
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

.survey-subtitle.warning { color: #ffe082; }

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

.slider-container {
  flex: 1;
}

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
  background-color: #5a52e0;
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

.error-msg {
  margin-top: 16px;
  color: #e53935;
  font-weight: 600;
  font-size: 0.95rem;
}

.no-uid-notice {
  padding: 80px 40px;
  text-align: center;
  color: #888;
}

/* Spinner overlay */
.spinner-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.spinner {
  width: 64px;
  height: 64px;
  border: 6px solid rgba(255, 255, 255, 0.25);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.9s linear infinite;
}

.spinner-text {
  margin-top: 20px;
  color: #fff;
  font-size: 1rem;
  font-weight: 600;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
