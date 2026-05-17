<template>
  <div class="device-block">
    <div class="card">
      <h1>{{ $t('deviceBlock.title') }}</h1>
      <p class="lead">{{ $t('deviceBlock.lead') }}</p>

      <section class="zoom-tip">
        <h2>{{ $t('deviceBlock.zoomTitle') }}</h2>
        <p>{{ $t('deviceBlock.zoomLead') }}</p>
        <ul>
          <li><strong>Windows</strong>：{{ $t('deviceBlock.zoomWindows') }}</li>
          <li><strong>macOS</strong>：{{ $t('deviceBlock.zoomMac') }}</li>
        </ul>
        <p class="reset">{{ $t('deviceBlock.zoomReset') }}</p>
        <button class="retry-btn" @click="retry">{{ $t('deviceBlock.retry') }}</button>
      </section>

      <p class="action">{{ $t('deviceBlock.action') }}</p>
      <p class="contact">
        {{ $t('deviceBlock.contactPrefix') }}<a href="mailto:sharon.lin@iss.nthu.edu.tw">sharon.lin@iss.nthu.edu.tw</a>
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DeviceBlockPage',
  methods: {
    retry() {
      this.$router.push({ name: 'Entry' });
    },
  },
};
</script>

<style scoped>
.device-block {
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
  font-size: 1.6rem;
  font-weight: 900;
  color: #6c63ff;
  margin: 0 0 24px;
  letter-spacing: -0.5px;
}
.card p { margin: 0 0 16px; font-size: 1rem; }
.card .lead { font-size: 1.05rem; color: #333; }
.card .action { margin-top: 28px; font-weight: 600; color: #333; }
.card .contact { margin-top: 28px; font-size: 0.9rem; color: #777; }
.card a { color: #6c63ff; text-decoration: none; font-weight: 600; }
.card a:hover { text-decoration: underline; }

.zoom-tip {
  margin-top: 28px;
  padding: 20px 24px;
  border: 1px solid #e0dfff;
  background: #f7f7ff;
  border-radius: 12px;
  text-align: left;
  line-height: 1.7;
}
.zoom-tip h2 {
  font-size: 1.05rem;
  font-weight: 700;
  color: #4a42d6;
  margin: 0 0 10px;
}
.zoom-tip p { margin: 0 0 10px; font-size: 0.95rem; color: #444; }
.zoom-tip ul {
  margin: 0 0 12px;
  padding-left: 20px;
  font-size: 0.95rem;
  color: #444;
}
.zoom-tip li { margin-bottom: 4px; }
.zoom-tip .reset { font-size: 0.85rem; color: #777; margin-bottom: 16px; }

.retry-btn {
  display: inline-block;
  background: #6c63ff;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 10px 24px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s, box-shadow 0.15s;
}
.retry-btn:hover {
  background: #5a52e0;
  box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
}
</style>
