<template>
  <LangToggle />
  <router-view />
</template>

<script>
import LangToggle from '@/components/LangToggle.vue';

export default {
  name: 'App',
  components: { LangToggle },
};
</script>

<style>
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Inter', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  background: #f5f7fa;
  color: #333;
}
</style>
