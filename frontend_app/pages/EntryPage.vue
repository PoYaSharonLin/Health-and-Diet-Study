<template>
  <div class="entry-wrapper">
    <div class="spinner" aria-hidden="true"></div>
    <p class="entry-text">{{ $t('entry.preparing') }}</p>
  </div>
</template>

<script>
import axios from 'axios';
import { isMobileOrTablet } from '@/lib/device';

const PRE_SURVEY_URL = 'https://www.surveycake.com/s/mYWoK';
const USER_ID_KEY = 'survey_user_id';

export default {
  name: 'EntryPage',

  async created() {
    if (isMobileOrTablet()) {
      this.$router.replace({ name: 'DeviceBlock' });
      return;
    }

    const uid = localStorage.getItem(USER_ID_KEY) || crypto.randomUUID();
    localStorage.setItem(USER_ID_KEY, uid);

    try {
      const { data } = await axios.post('/api/assignment/next', { respondent_id: uid });
      const condition = data?.data?.condition;
      if (!condition) throw new Error('Missing condition in response');

      const url = new URL(PRE_SURVEY_URL);
      url.searchParams.set('uid', uid);
      url.searchParams.set('condition', condition);
      window.location.replace(url.toString());
    } catch (err) {
      console.error('[entry] condition assignment failed:', err);
      this.$router.replace({ name: 'Invalid' });
    }
  },
};
</script>

<style scoped>
.entry-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 24px;
  background: #f4f7f6;
  font-family: 'Inter', sans-serif;
  color: #555;
}

.spinner {
  width: 56px;
  height: 56px;
  border: 5px solid rgba(108, 99, 255, 0.2);
  border-top-color: #6c63ff;
  border-radius: 50%;
  animation: spin 0.9s linear infinite;
  margin-bottom: 20px;
}

.entry-text {
  font-size: 1rem;
  margin: 0;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
