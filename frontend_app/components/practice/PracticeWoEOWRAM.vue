<template>
  <section class="practice-intro">
    <i18n-t keypath="practice.intro.lead" tag="p" scope="global">
      <template #strong><strong>{{ $t('practice.intro.leadStrong') }}</strong></template>
    </i18n-t>
    <p class="variant-placeholder">{{ $t('practice.variantPlaceholder.woEOwRAM') }}</p>
  </section>
</template>

<script>
export default { name: 'PracticeWoEOWRAM' };
</script>

<style scoped>
.practice-intro {
  margin-bottom: 32px;
  text-align: center;
  color: #555;
  line-height: 1.7;
  font-size: 1rem;
}
.variant-placeholder {
  margin-top: 16px;
  padding: 12px 16px;
  border: 1px dashed #c0c4ff;
  border-radius: 8px;
  background: #f7f8ff;
  color: #6c63ff;
  font-size: 0.9rem;
}
</style>
