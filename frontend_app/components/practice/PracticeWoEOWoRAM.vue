<template>
  <section class="practice-intro">
    <i18n-t keypath="practice.intro.lead" tag="p" scope="global">
      <template #strong><strong>{{ $t('practice.intro.leadStrong') }}</strong></template>
    </i18n-t>
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
</style>
