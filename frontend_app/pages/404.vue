<template>
  <div class="not-found">
    <div class="card">
      <h1>{{ $t('notFound.title') }}</h1>
      <p class="lead">{{ $t('notFound.lead') }}</p>
      <i18n-t keypath="notFound.warn" tag="p" scope="global">
        <template #strong><strong>{{ $t('notFound.warnStrong') }}</strong></template>
      </i18n-t>
      <p class="action">{{ $t('notFound.action') }}</p>
      <p class="contact">
        {{ $t('notFound.contactPrefix') }}<a href="mailto:sharon.lin@iss.nthu.edu.tw">sharon.lin@iss.nthu.edu.tw</a>
      </p>
    </div>
  </div>
</template>

<script>
export default { name: 'NotFound' };
</script>

<style scoped>
.not-found {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 48px 16px;
  font-family: 'Inter', sans-serif;
  background: #f4f7f6;
  color: #444;
}
.card {
  width: 100%;
  max-width: 640px;
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 8px 48px rgba(108, 99, 255, 0.12);
  padding: 48px 40px;
  text-align: center;
  line-height: 1.8;
}
.card h1 {
  font-size: 1.8rem;
  font-weight: 900;
  color: #6c63ff;
  margin: 0 0 24px;
  letter-spacing: -0.5px;
}
.card p { margin: 0 0 16px; font-size: 1rem; }
.card .lead { font-size: 1.05rem; color: #333; }
.card .action { margin-top: 24px; font-weight: 600; color: #333; }
.card .contact { margin-top: 32px; font-size: 0.9rem; color: #777; }
.card a { color: #6c63ff; text-decoration: none; font-weight: 600; }
.card a:hover { text-decoration: underline; }
</style>
