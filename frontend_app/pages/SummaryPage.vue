<template>
  <div class="survey-wrapper" data-track="page-background">
    <BehaviorTracker>
      <div class="survey-page">
        <header class="survey-header" data-track="page-header">
          <h1 class="survey-title">{{ $t('summary.title') }}</h1>
          <p class="survey-subtitle">{{ $t('summary.subtitle') }}</p>
        </header>

        <main v-if="userId && dietary.length === questions.length" class="survey-body">
          <section class="score-section" data-track="page-score">
            <span class="score-label">{{ $t('summary.score.label') }}</span>
            <span class="score-value">{{ totalScore }}</span>
            <span class="score-range">/ {{ maxTotal }}</span>
            <span class="score-hint">{{ $t('summary.score.hint') }}</span>
          </section>

          <table class="summary-table" data-track="summary-table">
            <thead>
              <tr>
                <th class="col-num">{{ $t('summary.tableHeaders.num') }}</th>
                <th class="col-question">{{ $t('summary.tableHeaders.question') }}</th>
                <th class="col-score">{{ $t('summary.tableHeaders.score') }}</th>
                <th class="col-bar">{{ $t('summary.tableHeaders.bar') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(q, index) in questions"
                :key="index"
                :data-track="'sq' + (index + 1) + '-row'"
              >
                <td class="col-num">{{ index + 1 }}</td>
                <td class="col-question" :data-track="'sq' + (index + 1) + '-label'">
                  {{ q.text }}
                </td>
                <td class="col-score" :data-track="'sq' + (index + 1) + '-score'">
                  <span class="score-num">{{ dietary[index] }}</span>
                  <span class="score-denom">/ {{ sliderMax }}</span>
                </td>
                <td class="col-bar">
                  <div
                    class="bar-track"
                    role="progressbar"
                    :aria-valuenow="dietary[index]"
                    :aria-valuemin="sliderMin"
                    :aria-valuemax="sliderMax"
                  >
                    <div
                      class="bar-fill"
                      :style="{ width: barPercent(dietary[index]) + '%' }"
                    ></div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <section class="suggestions-section" data-track="summary-suggestions">
            <h2 class="suggestions-title">{{ $t('summary.suggestions.title') }}</h2>
            <p class="suggestions-intro">{{ $t('summary.suggestions.intro') }}</p>
            <div
              v-for="(s, i) in suggestionItems"
              :key="'sug-' + i"
              class="suggestion-item"
              :data-track="'suggestion-' + i"
            >
              <h3 class="suggestion-range">{{ s.range }}</h3>
              <p class="suggestion-body">{{ s.body }}</p>
            </div>
          </section>

          <section class="post-intro" data-track="postsurvey-intro">
            <h2>{{ $t('summary.postIntro.h2') }}</h2>
            <p>{{ $t('summary.postIntro.p') }}</p>
          </section>

          <div
            v-for="(q, index) in postQuestions"
            :key="'pq-' + index"
            class="survey-section"
            :data-track="'pq' + (index + 1) + '-element'"
          >
            <label class="question-label" :data-track="'pq' + (index + 1) + '-label'">
              ({{ index + 1 }}) {{ q.text }} *
            </label>
            <div class="slider-container">
              <SliderBar
                v-model="postAnswers[index]"
                :track-prefix="'pq' + (index + 1)"
                :min="sliderMin"
                :max="sliderMax"
                :step="1"
                :minLabel="q.minLabel"
                :maxLabel="q.maxLabel"
                :finished="postConfirmed[index]"
                @interact="onPostInteract(index)"
                @change="onPostInteract(index)"
              />
            </div>
            <div class="confirm-container">
              <button
                class="confirm-btn"
                :class="{ confirmed: postConfirmed[index], disabled: !canConfirmPost(index) }"
                :disabled="!canConfirmPost(index)"
                @click="confirmAnswer(index)"
                :data-track="'pq' + (index + 1) + '-confirm'"
                :title="postConfirmTitle(index)"
              >
                <span class="icon">✓</span>
              </button>
            </div>
          </div>

          <div class="submit-row">
            <p v-if="!allConfirmed && !submitted" class="validation-hint">
              {{ $t('summary.validationHint', { done: confirmedCount, total: postQuestions.length }) }}
            </p>
            <button
              class="submit-btn"
              data-track="postsurvey-submit"
              :disabled="submitting || submitted || !allConfirmed"
              @click="submit"
            >
              {{ $t('summary.submitBtn') }}
            </button>
            <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
          </div>
        </main>

        <div v-else class="no-uid-notice">
          <p>{{ $t('summary.noAnswers') }}</p>
        </div>
      </div>
    </BehaviorTracker>

    <div v-if="submitting" class="spinner-overlay">
      <div class="spinner"></div>
      <p class="spinner-text">{{ $t('summary.spinnerText') }}</p>
    </div>
  </div>
</template>

<script>
import BehaviorTracker from '@/components/BehaviorTracker.vue';
import SliderBar       from '@/components/SliderBar.vue';
import session         from '@/lib/session';
import tracker         from '@/lib/tracker';

const SLIDER_MIN = 0;
const SLIDER_MAX = 9;

export default {
  name: 'SummaryPage',

  components: { BehaviorTracker, SliderBar },

  data() {
    const flags = session.resolveFlags();
    const postDefault = flags?.hasRAM ? SLIDER_MIN : SLIDER_MAX;
    return {
      userId:     null,
      dietary:    [],
      submitting: false,
      submitted:  false,
      errorMsg:   '',
      sliderMin:  SLIDER_MIN,
      sliderMax:  SLIDER_MAX,
      postAnswers:       Array(3).fill(postDefault),
      postConfirmed:     Array(3).fill(false),
      postSliderTouched: Array(3).fill(false),
    };
  },

  async created() {
    this.userId = await session.init();
    const raw = sessionStorage.getItem('survey_answers_v1');
    if (raw) {
      try {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed.dietary)) this.dietary = parsed.dietary;
      } catch (_) { /* ignore malformed data */ }
    }
  },

  computed: {
    questions() {
      return this.$tm('survey.questions').map(q => ({
        text:     this.$rt(q.text),
        minLabel: this.$rt(q.minLabel),
        maxLabel: this.$rt(q.maxLabel),
      }));
    },
    postQuestions() {
      return this.$tm('summary.postQuestions').map(q => ({
        text:     this.$rt(q.text),
        minLabel: this.$rt(q.minLabel),
        maxLabel: this.$rt(q.maxLabel),
      }));
    },
    suggestionItems() {
      return this.$tm('summary.suggestions.items').map(s => ({
        range: this.$rt(s.range),
        body:  this.$rt(s.body),
      }));
    },
    totalScore() {
      return this.dietary.reduce((sum, v) => sum + (Number(v) || 0), 0);
    },
    maxTotal() {
      return this.questions.length * this.sliderMax;
    },
    confirmedCount() {
      return this.postConfirmed.filter(Boolean).length;
    },
    allConfirmed() {
      return this.postConfirmed.every(Boolean);
    },
  },

  methods: {
    barPercent(value) {
      const v = Number(value) || 0;
      const range = this.sliderMax - this.sliderMin;
      if (range <= 0) return 0;
      return Math.max(0, Math.min(100, ((v - this.sliderMin) / range) * 100));
    },

    onPostInteract(index) {
      this.postSliderTouched[index] = true;
    },
    canConfirmPost(index) {
      return this.postConfirmed[index] || this.postSliderTouched[index];
    },
    postConfirmTitle(index) {
      if (this.postConfirmed[index]) return this.$t('common.confirmTitle.confirmed');
      if (!this.postSliderTouched[index]) return this.$t('common.confirmTitle.notTouchedClick');
      return this.$t('common.confirmTitle.ready');
    },
    confirmAnswer(index) {
      // One-way lock: once confirmed, the answer can no longer be changed.
      if (this.postConfirmed[index]) return;
      if (!this.canConfirmPost(index)) return;
      this.postConfirmed[index] = true;
    },

    async submit() {
      if (this.submitting || this.submitted || !this.allConfirmed) return;
      this.errorMsg   = '';
      this.submitting = true;

      const startedAt = Date.now();
      const minSpinnerMs = 1000;

      try {
        await import('axios').then(({ default: axios }) =>
          axios.post('/api/survey/session', {
            respondent_id: this.userId,
            metadata: {
              answers:      this.dietary,
              post_answers: this.postAnswers,
              submitted_at: new Date().toISOString(),
            },
          })
        );

        const presignRes = await fetch(
          `/api/behavior/${encodeURIComponent(this.userId)}/presigned-url`
        );
        if (!presignRes.ok) {
          throw new Error(`presigned-url failed: ${presignRes.status}`);
        }
        const { url, key, expires_at } = await presignRes.json();
        console.log('[presigned-url] url:', url, '| key:', key, '| expires_at:', expires_at);

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

        const elapsed = Date.now() - startedAt;
        if (elapsed < minSpinnerMs) {
          await new Promise(r => setTimeout(r, minSpinnerMs - elapsed));
        }

        this.submitted = true;

        const postSurveyUrl = new URL('https://zh.research.net/r/N5L8Z9Q');
        postSurveyUrl.searchParams.set('uid', this.userId);
        const condition = session.getCondition();
        if (condition) postSurveyUrl.searchParams.set('condition', condition);
        window.location.href = postSurveyUrl.toString();
      } catch (err) {
        console.error('[summary submit] error:', err);
        const elapsed = Date.now() - startedAt;
        if (elapsed < minSpinnerMs) {
          await new Promise(r => setTimeout(r, minSpinnerMs - elapsed));
        }
        this.errorMsg = this.$t('summary.errorMsg');
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
  padding: 24px 16px 48px;
  font-family: 'Inter', sans-serif;
}

.survey-page {
  width: 100%;
  max-width: 880px;
  margin: 0 auto;
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 8px 48px rgba(108, 99, 255, 0.12);
  overflow: hidden;
}

.survey-header {
  background: #6c63ff;
  padding: 24px 32px;
  color: #fff;
  text-align: center;
}

.survey-title {
  font-size: 1.5rem;
  font-weight: 900;
  margin: 0 0 4px;
  letter-spacing: -0.5px;
}

.survey-subtitle {
  margin: 0;
  font-size: 0.85rem;
  opacity: 0.9;
}

.survey-body {
  padding: 24px 32px 32px;
}

.score-section {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 8px;
  padding: 12px 18px;
  margin-bottom: 14px;
  background: linear-gradient(135deg, #f0f0ff 0%, #eef7ff 100%);
  border-radius: 10px;
  border: 1px solid #e0dfff;
}

.score-label {
  font-size: 0.85rem;
  color: #6c63ff;
  font-weight: 700;
  letter-spacing: 1px;
}

.score-value {
  font-size: 1.7rem;
  font-weight: 900;
  color: #4a42d6;
  line-height: 1;
}

.score-range {
  font-size: 0.95rem;
  font-weight: 600;
  color: #999;
}

.score-hint {
  margin-left: auto;
  font-size: 0.78rem;
  color: #777;
}

.summary-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.88rem;
  table-layout: fixed;
}

.summary-table thead th {
  text-align: left;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 1px;
  color: #888;
  padding: 6px 8px;
  border-bottom: 2px solid #eee;
  text-transform: uppercase;
}

.summary-table tbody td {
  padding: 8px;
  border-bottom: 1px solid #f0f0f0;
  vertical-align: middle;
  line-height: 1.45;
}

.summary-table tbody tr:last-child td {
  border-bottom: none;
}

.col-num {
  width: 32px;
  text-align: center;
  color: #aaa;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
}

.col-question {
  color: #333;
  font-weight: 500;
  word-break: break-word;
}

.col-score {
  width: 68px;
  text-align: right;
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
}

.score-num {
  font-size: 1.05rem;
  font-weight: 800;
  color: #4a42d6;
}

.score-denom {
  font-size: 0.78rem;
  color: #aaa;
  margin-left: 2px;
}

.col-bar {
  width: 38%;
}

.bar-track {
  width: 100%;
  height: 10px;
  background: #ececf3;
  border-radius: 999px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #6c63ff, #8a83ff);
  border-radius: 999px;
  transition: width 0.3s ease;
}

.suggestions-section {
  margin: 32px 0 20px;
  padding-top: 24px;
  border-top: 2px solid #eee;
}

.suggestions-title {
  font-size: 1.5rem;
  font-weight: 500;
  color: #555;
  margin: 0 0 14px;
}

.suggestions-intro {
  color: #777;
  font-size: 0.9rem;
  line-height: 1.6;
  margin: 0 0 12px;
}

.suggestion-item {
  padding: 16px 0;
  border-bottom: 1px solid #eee;
}

.suggestion-item:last-child {
  border-bottom: none;
}

.suggestion-range {
  font-size: 1.1rem;
  font-weight: 600;
  color: #555;
  margin: 0 0 10px;
}

.suggestion-body {
  color: #777;
  font-size: 0.9rem;
  line-height: 1.6;
  margin: 0;
}

.post-intro {
  margin: 32px 0 20px;
  padding-top: 24px;
  border-top: 2px solid #eee;
  text-align: center;
}

.post-intro h2 {
  font-size: 1.3rem;
  font-weight: 700;
  color: #333;
  margin: 0 0 8px;
}

.post-intro p {
  color: #666;
  line-height: 1.5;
  margin: 0;
  font-size: 0.9rem;
}

.survey-section {
  margin-bottom: 24px;
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
  margin-bottom: 16px;
  line-height: 1.5;
}

.slider-container {
  flex: 1;
}

.confirm-container {
  margin-top: 14px;
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

.confirm-btn.disabled,
.confirm-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.confirm-btn.disabled:hover,
.confirm-btn:disabled:hover {
  background: #fff;
}

.submit-row {
  text-align: center;
  margin-top: 32px;
}

.submit-btn {
  background: #6c63ff;
  color: #fff;
  border: none;
  border-radius: 50px;
  padding: 14px 56px;
  font-size: 1.05rem;
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
  padding: 60px 32px;
  text-align: center;
  color: #888;
}

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
