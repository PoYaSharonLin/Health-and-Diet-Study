<template>
  <ContentLayout :title="$t('doctorRecommendation.title')" @next="goNext">
    <p class="body" data-track="docrec-body">{{ bodyText }}</p>

    <img
      :src="image"
      :alt="$t('doctorRecommendation.imageAlt')"
      class="doctor-image"
      data-track="docrec-image"
    />

    <p class="note" data-track="docrec-note">{{ $t('doctorRecommendation.note') }}</p>

    <h3 class="section-h3">{{ $t('doctorRecommendation.reminderHeading') }}</h3>
    <ol class="reminders" data-track="docrec-reminders">
      <li v-for="(r, i) in reminders" :key="i">{{ r }}</li>
    </ol>
  </ContentLayout>
</template>

<script>
import ContentLayout from '@/components/ContentLayout.vue';
import session from '@/lib/session';
import { getAssets } from '@/lib/conditionAssets';

export default {
  name: 'DoctorRecommendationPage',
  components: { ContentLayout },
  computed: {
    diseaseName() {
      const key = session.getDisease();
      return key ? this.$t(`diseases.${key}`) : '';
    },
    bodyText() {
      return this.$t('doctorRecommendation.body').replace(/\{disease\}/g, this.diseaseName);
    },
    reminders() {
      return this.$tm('doctorRecommendation.reminders').map(r => this.$rt(r));
    },
    image() {
      const cond = session.getCondition();
      return cond ? getAssets(cond).drZhang : '';
    },
  },
  methods: {
    goNext() {
      sessionStorage.setItem('doctor_recommendation_done', '1');
      const uid = session.getUserId();
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/consultation-reminder${query}`);
    },
  },
};
</script>

<style scoped>
.body { margin: 0 0 20px; line-height: 1.75; color: #333; }
.doctor-image {
  display: block;
  max-width: 100%;
  height: auto;
  margin: 0 auto 24px;
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}
.note {
  background: #fff8e1;
  border-left: 4px solid #ffb300;
  padding: 14px 18px;
  border-radius: 8px;
  margin: 0 0 28px;
  color: #6d4c00;
  line-height: 1.7;
}
.section-h3 {
  font-size: 1.1rem;
  font-weight: 700;
  margin: 0 0 12px;
  color: #333;
}
.reminders {
  padding-left: 22px;
  margin: 0;
}
.reminders li {
  margin-bottom: 10px;
  line-height: 1.7;
}
</style>
