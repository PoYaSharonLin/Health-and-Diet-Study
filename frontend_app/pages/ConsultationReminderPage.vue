<template>
  <ContentLayout :title="$t('consultationReminder.title')" @next="goNext">
    <img
      :src="image"
      :alt="$t('consultationReminder.imageAlt')"
      class="consult-image"
      data-track="consult-image"
    />

    <p class="body" data-track="consult-intro">{{ introText }}</p>
    <p class="body" data-track="consult-explain">{{ explainText }}</p>

    <h3 class="section-h3">{{ $t('consultationReminder.sliderHeading') }}</h3>
    <ol class="slider-rules" data-track="consult-rules">
      <li v-for="(s, i) in sliderInstructions" :key="i">{{ s }}</li>
    </ol>
  </ContentLayout>
</template>

<script>
import ContentLayout from '@/components/ContentLayout.vue';
import session from '@/lib/session';
import { getAssets } from '@/lib/conditionAssets';

export default {
  name: 'ConsultationReminderPage',
  components: { ContentLayout },
  computed: {
    diseaseName() {
      const key = session.getDisease();
      return key ? this.$t(`diseases.${key}`) : '';
    },
    introText() {
      return this.$t('consultationReminder.intro').replace(/\{disease\}/g, this.diseaseName);
    },
    explainText() {
      return this.$t('consultationReminder.explain').replace(/\{disease\}/g, this.diseaseName);
    },
    sliderInstructions() {
      return this.$tm('consultationReminder.sliderInstructions').map(s => this.$rt(s));
    },
    image() {
      const cond = session.getCondition();
      return cond ? getAssets(cond).initialConsultation : '';
    },
  },
  methods: {
    goNext() {
      sessionStorage.setItem('consultation_reminder_done', '1');
      const uid = session.getUserId();
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/practice${query}`);
    },
  },
};
</script>

<style scoped>
.consult-image {
  display: block;
  max-width: 100%;
  height: auto;
  margin: 0 auto 24px;
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}
.body { margin: 0 0 18px; line-height: 1.75; color: #333; }
.section-h3 {
  font-size: 1.1rem;
  font-weight: 700;
  margin: 20px 0 12px;
  color: #333;
}
.slider-rules {
  padding-left: 22px;
  margin: 0;
}
.slider-rules li {
  margin-bottom: 10px;
  line-height: 1.7;
}
</style>
