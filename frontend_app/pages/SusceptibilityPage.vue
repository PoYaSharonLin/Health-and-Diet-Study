<template>
  <ContentLayout :title="$t('susceptibility.title')" @next="goNext">
    <img
      :src="image"
      :alt="$t('susceptibility.title')"
      class="hero-image"
      data-track="susceptibility-image"
    />

    <p v-if="!hasEO" class="body" data-track="susceptibility-body">
      {{ $t('susceptibility.woEO.body') }}
    </p>

    <template v-else>
      <h2 class="section-h2" data-track="susceptibility-weo-title">
        {{ $t('susceptibility.wEO.title') }}
      </h2>
      <p class="body" data-track="susceptibility-weo-lead">
        {{ $t('susceptibility.wEO.lead') }}
      </p>
      <p class="callout" data-track="susceptibility-weo-engagement">
        {{ $t('susceptibility.wEO.engagement') }}
      </p>

      <h3 class="section-h3">{{ $t('susceptibility.wEO.scenarioTitle') }}</h3>
      <ol class="scenario" data-track="susceptibility-weo-scenario">
        <li v-for="(step, i) in scenarioSteps" :key="i">{{ step }}</li>
      </ol>
    </template>
  </ContentLayout>
</template>

<script>
import ContentLayout from '@/components/ContentLayout.vue';
import session from '@/lib/session';
import { getAssets } from '@/lib/conditionAssets';

export default {
  name: 'SusceptibilityPage',
  components: { ContentLayout },
  computed: {
    hasEO() {
      return session.getFlags()?.hasEO ?? false;
    },
    image() {
      const cond = session.getCondition();
      return cond ? getAssets(cond).susceptibility : '';
    },
    scenarioSteps() {
      return this.$tm('susceptibility.wEO.scenarioSteps').map(s => this.$rt(s));
    },
  },
  methods: {
    goNext() {
      sessionStorage.setItem('susceptibility_done', '1');
      const uid = session.getUserId();
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/severity${query}`);
    },
  },
};
</script>

<style scoped>
.hero-image {
  display: block;
  max-width: 100%;
  height: auto;
  margin: 0 auto 24px;
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}
.body { margin: 0 0 20px; font-size: 1rem; line-height: 1.75; color: #333; }
.callout {
  background: #fff8e1;
  border-left: 4px solid #ffb300;
  padding: 12px 16px;
  border-radius: 8px;
  margin: 16px 0 24px;
  color: #6d4c00;
}
.section-h2 { font-size: 1.25rem; font-weight: 700; margin: 8px 0 16px; color: #333; }
.section-h3 { font-size: 1.1rem; font-weight: 700; margin: 24px 0 12px; color: #333; }
.scenario {
  list-style: none;
  padding-left: 0;
  counter-reset: step;
}
.scenario li {
  position: relative;
  padding: 12px 16px 12px 48px;
  margin: 0 0 12px;
  background: #f7f8ff;
  border-radius: 8px;
  line-height: 1.7;
}
.scenario li::before {
  counter-increment: step;
  content: counter(step);
  position: absolute;
  left: 14px;
  top: 12px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #6c63ff;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.85rem;
  font-weight: 700;
}
</style>
