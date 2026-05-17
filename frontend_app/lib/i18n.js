import { createI18n } from 'vue-i18n';
import zh from '../locales/zh.json';
import en from '../locales/en.json';

const LOCALE_KEY = 'survey_locale';
const SUPPORTED  = ['zh', 'en'];

export const IS_DEV = process.env.NODE_ENV !== 'production';

function pickInitialLocale() {
  if (!IS_DEV) return 'zh';
  const saved = localStorage.getItem(LOCALE_KEY);
  if (saved && SUPPORTED.includes(saved)) return saved;
  return 'en';
}

const i18n = createI18n({
  legacy:         true,
  locale:         pickInitialLocale(),
  fallbackLocale: 'zh',
  messages:       { zh, en },
});

export function setLocale(loc) {
  if (!SUPPORTED.includes(loc)) return;
  i18n.global.locale = loc;
  if (IS_DEV) {
    localStorage.setItem(LOCALE_KEY, loc);
  }
}

export function getLocale() {
  return i18n.global.locale;
}

export { SUPPORTED };
export default i18n;
