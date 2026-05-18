<template>
  <ContentLayout
    :title="$t('doctorPreference.title')"
    :can-advance="allAnswered"
    :hint="allAnswered ? '' : $t('doctorPreference.validationHint')"
    @next="goNext"
  >
    <p class="lead" data-track="docpref-lead">{{ leadText }}</p>

    <section
      v-for="(q, qi) in questions"
      :key="q.key"
      class="question-block"
      :data-track="'docpref-q' + (qi + 1)"
    >
      <h3 class="q-title">{{ qi + 1 }}. {{ interpolate(q.text) }}</h3>
      <div class="options">
        <label
          v-for="opt in q.options"
          :key="opt.value"
          class="opt-row"
          :class="{ active: answers[q.key] === opt.value }"
        >
          <input
            type="radio"
            :name="q.key"
            :value="opt.value"
            v-model="answers[q.key]"
            :data-track="'docpref-q' + (qi + 1) + '-' + opt.value"
          />
          <span class="opt-label">{{ opt.label }}</span>
        </label>
      </div>
    </section>
  </ContentLayout>
</template>

<script>
import ContentLayout from '@/components/ContentLayout.vue';
import session from '@/lib/session';

const STORAGE_KEY = 'doctor_preference_answers';

export default {
  name: 'DoctorPreferencePage',
  components: { ContentLayout },
  data() {
    return {
      answers: { style: '', pace: '', info: '' },
    };
  },
  created() {
    const saved = sessionStorage.getItem(STORAGE_KEY);
    if (saved) {
      try { Object.assign(this.answers, JSON.parse(saved)); }
      catch (_) { /* ignore malformed draft */ }
    }
  },
  watch: {
    answers: {
      deep: true,
      handler(v) { sessionStorage.setItem(STORAGE_KEY, JSON.stringify(v)); },
    },
  },
  computed: {
    diseaseName() {
      const key = session.getDisease();
      return key ? this.$t(`diseases.${key}`) : '';
    },
    leadText() {
      return this.interpolate(this.$t('doctorPreference.lead'));
    },
    questions() {
      return this.$tm('doctorPreference.questions').map(q => ({
        key:  this.$rt(q.key),
        text: this.$rt(q.text),
        options: q.options.map(o => ({
          value: this.$rt(o.value),
          label: this.$rt(o.label),
        })),
      }));
    },
    allAnswered() {
      return ['style', 'pace', 'info'].every(k => !!this.answers[k]);
    },
  },
  methods: {
    interpolate(s) {
      return s.replace(/\{disease\}/g, this.diseaseName);
    },
    goNext() {
      if (!this.allAnswered) return;
      sessionStorage.setItem('doctor_preference_done', '1');
      const uid = session.getUserId();
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/doctor-recommendation${query}`);
    },
  },
};
</script>

<style scoped>
.lead {
  margin: 0 0 24px;
  line-height: 1.7;
  color: #444;
}
.question-block {
  margin-bottom: 28px;
  padding: 20px 24px;
  border: 1px solid #f0f0f0;
  border-radius: 12px;
  background: #fafafa;
}
.q-title {
  font-size: 1.05rem;
  font-weight: 600;
  color: #333;
  margin: 0 0 16px;
  line-height: 1.6;
}
.options {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.opt-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border: 1.5px solid #e0e0e0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
}
.opt-row:hover {
  border-color: #6c63ff;
  background: #f7f8ff;
}
.opt-row.active {
  border-color: #6c63ff;
  background: #f0f1ff;
}
.opt-row input { accent-color: #6c63ff; }
.opt-label { color: #333; }
</style>
