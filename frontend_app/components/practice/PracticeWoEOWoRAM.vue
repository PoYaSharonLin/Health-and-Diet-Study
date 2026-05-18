<template>
  <section class="practice-intro">
    <i18n-t keypath="practice.intro.lead" tag="p" scope="global">
      <template #strong><strong>{{ $t('practice.intro.leadStrong') }}</strong></template>
    </i18n-t>
    <p class="ram-notice">{{ $t('practice.intro.ramNoticeWoRAM') }}</p>
  </section>
</template>

<script>
export default { name: 'PracticeWoEOWoRAM' };
</script>

<style scoped>
.practice-intro {
  margin-bottom: 32px;
  text-align: center;
  color: #555;
  line-height: 1.7;
  font-size: 1rem;
}
.ram-notice {
  margin: 16px auto 0;
  max-width: 640px;
  padding: 12px 16px;
  background: #e3f2fd;
  border-left: 4px solid #2196f3;
  border-radius: 8px;
  color: #0d47a1;
  font-size: 0.95rem;
  text-align: left;
}
</style>
