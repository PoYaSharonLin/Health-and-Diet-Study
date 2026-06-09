<template>
  <ContentLayout :title="$t('severity.title')" @next="goNext">
    <template v-if="!hasEO">
      <img
        :src="image"
        :alt="$t('severity.title')"
        class="hero-image"
        data-track="severity-image"
      />
      <p class="body" data-track="severity-woeo-framing">{{ $t('severity.woEO.framing') }}</p>

      <h2 class="section-h2" data-track="efficacy-woeo-heading">
        {{ $t('severity.woEO.heading') }}
      </h2>
      <p class="body">{{ $t('severity.woEO.intro') }}</p>
      <ul class="tool-list" data-track="efficacy-woeo-tools">
        <li v-for="(t, i) in tools" :key="i">
          <strong>{{ t.label }}：</strong>{{ t.body }}
        </li>
      </ul>
      <p class="body">{{ $t('severity.woEO.outro') }}</p>
    </template>

    <template v-else>
      <h2 class="section-h2">{{ $t('severity.wEO.heading') }}</h2>

      <img
        :src="susceptibilityImage"
        :alt="$t('susceptibility.title')"
        class="hero-image hero-image--inset"
        data-track="severity-susceptibility-image"
      />
      <h3 class="section-h3" data-track="severity-weo-section1-title">
        {{ $t('severity.wEO.section1.title') }}
      </h3>
      <i18n-t
        keypath="severity.wEO.section1.body"
        tag="p"
        class="body"
        scope="global"
        data-track="severity-weo-section1-body"
      >
        <template #strong1><strong>{{ $t('severity.wEO.section1.bodyStrong1') }}</strong></template>
        <template #strong2><strong>{{ $t('severity.wEO.section1.bodyStrong2') }}</strong></template>
      </i18n-t>

      <img
        :src="image"
        :alt="$t('severity.title')"
        class="hero-image hero-image--inset"
        data-track="severity-image"
      />
      <h3 class="section-h3" data-track="severity-weo-section2-title">
        {{ $t('severity.wEO.section2.title') }}
      </h3>
      <i18n-t
        keypath="severity.wEO.section2.body"
        tag="p"
        class="body"
        scope="global"
        data-track="severity-weo-section2-body"
      >
        <template #strong1><strong>{{ $t('severity.wEO.section2.bodyStrong1') }}</strong></template>
        <template #strong2><strong>{{ $t('severity.wEO.section2.bodyStrong2') }}</strong></template>
      </i18n-t>

      <i18n-t
        keypath="efficacy.title"
        tag="h2"
        class="section-h2 efficacy-heading"
        scope="global"
      >
        <template #strong><strong class="hl-red">{{ $t('efficacy.titleStrong') }}</strong></template>
      </i18n-t>

      <section class="efficacy-block" data-track="efficacy-response">
        <h3 class="efficacy-h3">{{ $t('efficacy.responseEfficacy.heading') }}</h3>
        <p class="body">{{ $t('efficacy.responseEfficacy.body') }}</p>
      </section>

      <section class="efficacy-block" data-track="efficacy-self">
        <h3 class="efficacy-h3">{{ $t('efficacy.selfEfficacy.heading') }}</h3>
        <ul class="item-list">
          <li v-for="(item, i) in selfEfficacyItems" :key="i">
            <span class="item-label">{{ item.label }}：</span>{{ item.body }}
          </li>
        </ul>
      </section>
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
    susceptibilityImage() {
      const cond = session.getCondition();
      return cond ? getAssets(cond).susceptibility : '';
    },
    tools() {
      return this.$tm('severity.woEO.tools').map(t => ({
        label: this.$rt(t.label),
        body:  this.$rt(t.body),
      }));
    },
    selfEfficacyItems() {
      return this.$tm('efficacy.selfEfficacy.items').map(it => ({
        label: this.$rt(it.label),
        body:  this.$rt(it.body),
      }));
    },
  },
  methods: {
    goNext() {
      sessionStorage.setItem('severity_done', '1');
      sessionStorage.setItem('efficacy_done', '1');
      const uid = session.getUserId();
      const query = uid ? `?uid=${encodeURIComponent(uid)}` : '';
      this.$router.push(`/doctor-preference${query}`);
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
.hero-image--inset {
  margin: 16px auto 24px;
}
.body { margin: 0 0 20px; line-height: 1.75; color: #333; }
.section-h2 { font-size: 1.25rem; font-weight: 400; margin: 8px 0 16px; color: #000; }
.section-h3 { font-size: 1.05rem; font-weight: 400; margin: 24px 0 8px; color: #000; }
.tool-list {
  padding-left: 20px;
  margin: 0 0 20px;
}
.tool-list li {
  margin-bottom: 12px;
  line-height: 1.7;
}

.efficacy-heading {
  margin-top: 40px;
  padding-top: 32px;
  border-top: 1px solid #e0e0e0;
}
.efficacy-block {
  margin-bottom: 28px;
  padding: 20px 24px;
  background: #f7f8ff;
  border-radius: 12px;
}
.efficacy-h3 {
  font-size: 1.15rem;
  font-weight: 400;
  margin: 0 0 12px;
  color: #000;
}
.hl-red { color: #e53935; font-weight: 700; }
.item-list { padding-left: 20px; margin: 0; }
.item-list li { margin-bottom: 10px; line-height: 1.7; }
.item-label { text-decoration: underline; font-weight: 400; }
</style>
