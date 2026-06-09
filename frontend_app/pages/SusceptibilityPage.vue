<template>
  <ContentLayout :title="$t('susceptibility.title')" @next="goNext">
    <template v-if="!hasEO">
      <img
        :src="image"
        :alt="$t('susceptibility.title')"
        class="hero-image"
        data-track="susceptibility-image"
      />
      <p class="body" data-track="susceptibility-body">
        {{ $t('susceptibility.woEO.body') }}
      </p>
    </template>

    <template v-else>
      <h2 class="section-h2" data-track="susceptibility-weo-title">
        {{ $t('susceptibility.wEO.title') }}
      </h2>
      <i18n-t
        keypath="susceptibility.wEO.lead"
        tag="p"
        class="body"
        scope="global"
        data-track="susceptibility-weo-lead"
      >
        <template #strong><strong>{{ $t('susceptibility.wEO.leadStrong') }}</strong></template>
      </i18n-t>
      <i18n-t
        keypath="susceptibility.wEO.engagement"
        tag="p"
        class="body"
        scope="global"
        data-track="susceptibility-weo-engagement"
      >
        <template #strong><strong>{{ $t('susceptibility.wEO.engagementStrong') }}</strong></template>
      </i18n-t>

      <hr class="scenario-divider" />

      <h3 class="section-h3">{{ $t('susceptibility.wEO.scenarioTitle') }}</h3>
      <div class="scenario" data-track="susceptibility-weo-scenario">
        <template v-for="(step, i) in scenarioSteps" :key="i">
          <div v-if="i > 0" class="scenario-arrow" aria-hidden="true">↓</div>
          <p class="scenario-step">{{ step }}</p>
        </template>
      </div>
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
.body :deep(strong) { font-weight: 700; color: #222; }
.section-h2 { font-size: 1.25rem; font-weight: 700; margin: 8px 0 16px; color: #333; }
.section-h3 { font-size: 1.1rem; font-weight: 700; margin: 24px 0 16px; color: #333; }

.scenario-divider {
  border: 0;
  border-top: 1px solid #e0e0e0;
  margin: 24px 0 8px;
}

.scenario {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 0;
  padding: 0;
}
.scenario-step {
  max-width: 620px;
  margin: 0;
  padding: 8px 16px;
  text-align: center;
  line-height: 1.75;
  color: #444;
}
.scenario-arrow {
  margin: 12px 0;
  color: #888;
  font-size: 1.25rem;
  line-height: 1;
}
</style>
