<template>
  <ContentLayout :title="$t('consultationReminder.title')" @next="goNext">
    <img
      :src="image"
      :alt="$t('consultationReminder.imageAlt')"
      class="consult-image"
      data-track="consult-image"
    />

    <i18n-t
      keypath="consultationReminder.intro"
      tag="p"
      class="body"
      scope="global"
      data-track="consult-intro"
    >
      <template #disease>{{ diseaseName }}</template>
      <template #strong><strong>{{ $t('consultationReminder.introStrong') }}</strong></template>
    </i18n-t>
    <i18n-t
      keypath="consultationReminder.explain"
      tag="p"
      class="body"
      scope="global"
      data-track="consult-explain"
    >
      <template #disease>{{ diseaseName }}</template>
      <template #strong><strong class="hl-red">{{ $t('consultationReminder.explainStrong') }}</strong></template>
    </i18n-t>

    <p class="body" data-track="consult-slider-lead">{{ $t('consultationReminder.sliderLead') }}</p>
    <ol class="slider-rules" data-track="consult-rules">
      <li>{{ $t('consultationReminder.sliderInstructions.0') }}</li>
      <i18n-t
        keypath="consultationReminder.sliderInstructions.1"
        tag="li"
        scope="global"
      >
        <template #strong><strong>{{ $t('consultationReminder.sliderInstructionStrong') }}</strong></template>
      </i18n-t>
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
      this.$router.push(`/survey${query}`);
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
.hl-red { color: #e53935; font-weight: 700; }
.slider-rules {
  padding-left: 22px;
  margin: 0;
}
.slider-rules li {
  margin-bottom: 10px;
  line-height: 1.7;
}
</style>
