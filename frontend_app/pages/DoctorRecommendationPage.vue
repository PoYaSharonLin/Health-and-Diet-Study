<template>
  <ContentLayout :title="$t('doctorRecommendation.title')" @next="goNext">
    <p class="body" data-track="docrec-body">{{ bodyText }}</p>

    <img
      :src="image"
      :alt="$t('doctorRecommendation.imageAlt')"
      class="doctor-image"
      data-track="docrec-image"
    />

    <i18n-t
      keypath="doctorRecommendation.note"
      tag="p"
      class="note"
      scope="global"
      data-track="docrec-note"
    >
      <template #b1><strong>{{ $t('doctorRecommendation.noteStrong.b1') }}</strong></template>
      <template #b2><strong>{{ $t('doctorRecommendation.noteStrong.b2') }}</strong></template>
      <template #b3><strong>{{ $t('doctorRecommendation.noteStrong.b3') }}</strong></template>
      <template #b4><strong>{{ $t('doctorRecommendation.noteStrong.b4') }}</strong></template>
    </i18n-t>

    <h3 class="section-h3">{{ $t('doctorRecommendation.reminderHeading') }}</h3>
    <ol class="reminders" data-track="docrec-reminders">
      <i18n-t
        v-for="(s, i) in reminderStrongs"
        :key="i"
        :keypath="`doctorRecommendation.reminders.${i}`"
        tag="li"
        scope="global"
      >
        <template #strong><strong>{{ s }}</strong></template>
      </i18n-t>
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
    bodyText() {
      let a = {};
      try { a = JSON.parse(sessionStorage.getItem('doctor_preference_answers')) || {}; }
      catch (_) { /* ignore malformed draft */ }
      const frag = (group, val) =>
        val ? this.$t(`doctorRecommendation.bodyFragments.${group}.${val}`) : '';
      return this.$t('doctorRecommendation.body', {
        style: frag('style', a.style),
        pace:  frag('pace',  a.pace),
        info:  frag('info',  a.info),
      });
    },
    reminderStrongs() {
      return this.$tm('doctorRecommendation.reminderStrong').map(s => this.$rt(s));
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
  margin: 0 0 28px;
  color: #333;
  line-height: 1.75;
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
