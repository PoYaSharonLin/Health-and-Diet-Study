<template>
  <ContentLayout :title="$t('severity.title')" @next="goNext">
    <img
      :src="image"
      :alt="$t('severity.title')"
      class="hero-image"
      data-track="severity-image"
    />

    <template v-if="!hasEO">
      <p class="body" data-track="severity-woeo-framing">{{ $t('severity.woEO.framing') }}</p>
    </template>

    <template v-else>
      <h2 class="section-h2">{{ $t('severity.wEO.heading') }}</h2>
      <h3 class="section-h3" data-track="severity-weo-section1-title">
        {{ $t('severity.wEO.section1.title') }}
      </h3>
      <p class="body" data-track="severity-weo-section1-body">
        {{ $t('severity.wEO.section1.body') }}
      </p>
      <h3 class="section-h3" data-track="severity-weo-section2-title">
        {{ $t('severity.wEO.section2.title') }}
      </h3>
      <p class="body" data-track="severity-weo-section2-body">
        {{ $t('severity.wEO.section2.body') }}
      </p>
    </template>
  </ContentLayout>
</template>

<script>
import ContentLayout from '@/components/ContentLayout.vue';
import session from '@/lib/session';
import { getAssets } from '@/lib/conditionAssets';

export default {
  name: 'SeverityPage',
  components: { ContentLayout },
  computed: {
    hasEO() {
      return session.getFlags()?.hasEO ?? false;
    },
    image() {
      const cond = session.getCondition();
      return cond ? getAssets(cond).severity : '';
    },
  },
  methods: {
    goNext() {
      sessionStorage.setItem('severity_done', '1');
      const uid = session.getUserId();
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/efficacy${query}`);
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
.body { margin: 0 0 20px; line-height: 1.75; color: #333; }
.section-h2 { font-size: 1.25rem; font-weight: 700; margin: 8px 0 16px; color: #333; }
.section-h3 { font-size: 1.05rem; font-weight: 700; margin: 24px 0 8px; color: #5a52d5; }
.tool-list {
  padding-left: 20px;
  margin: 0 0 20px;
}
.tool-list li {
  margin-bottom: 12px;
  line-height: 1.7;
}
</style>
