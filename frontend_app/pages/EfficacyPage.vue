<template>
  <ContentLayout :title="title" @next="goNext">
    <template v-if="!hasEO">
      <p class="body">{{ $t('severity.woEO.intro') }}</p>
      <ul class="tool-list" data-track="efficacy-woeo-tools">
        <li v-for="(t, i) in tools" :key="i">
          <strong>{{ t.label }}：</strong>{{ t.body }}
        </li>
      </ul>
      <p class="body">{{ $t('severity.woEO.outro') }}</p>
    </template>

    <template v-else>
      <section class="efficacy-block" data-track="efficacy-response">
        <h3 class="section-h3">{{ $t('efficacy.responseEfficacy.heading') }}</h3>
        <p class="body">{{ $t('efficacy.responseEfficacy.body') }}</p>
      </section>

      <section class="efficacy-block" data-track="efficacy-self">
        <h3 class="section-h3">{{ $t('efficacy.selfEfficacy.heading') }}</h3>
        <ul class="item-list">
          <li v-for="(item, i) in selfEfficacyItems" :key="i">
            <strong>{{ item.label }}：</strong>{{ item.body }}
          </li>
        </ul>
      </section>
    </template>
  </ContentLayout>
</template>

<script>
import ContentLayout from '@/components/ContentLayout.vue';
import session from '@/lib/session';

export default {
  name: 'EfficacyPage',
  components: { ContentLayout },
  computed: {
    hasEO() {
      return session.getFlags()?.hasEO ?? false;
    },
    title() {
      return this.hasEO ? this.$t('efficacy.title') : this.$t('severity.woEO.heading');
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
.section-h2 { font-size: 1.25rem; font-weight: 700; margin: 8px 0 16px; color: #333; }
.section-h3 {
  font-size: 1.15rem;
  font-weight: 700;
  margin: 0 0 12px;
  color: #5a52d5;
}
.body { margin: 0 0 20px; line-height: 1.75; color: #333; }
.efficacy-block {
  margin-bottom: 28px;
  padding: 20px 24px;
  background: #f7f8ff;
  border-radius: 12px;
}
.tool-list {
  padding-left: 20px;
  margin: 0 0 20px;
}
.tool-list li {
  margin-bottom: 12px;
  line-height: 1.7;
}
.item-list { padding-left: 20px; margin: 0; }
.item-list li { margin-bottom: 10px; line-height: 1.7; }
</style>
