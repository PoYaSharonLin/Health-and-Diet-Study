/**
 * session.js
 *
 * Manages the survey user session:
 * - Reads the unique user ID from the URL query param (?uid=...)
 * - Persists it in localStorage so it survives navigation without the param
 * - Registers the session with the backend on first visit
 */

import axios from 'axios';

const USER_ID_KEY    = 'survey_user_id';
const ORIG_URL_KEY   = 'survey_original_url';
const CONDITION_KEY  = 'survey_condition';
const DISEASE_KEY    = 'survey_disease';

export const VALID_CONDITIONS = ['woEO-woRAM', 'wEO-woRAM', 'woEO-wRAM', 'wEO-wRAM'];

export const VALID_DISEASES = [
  'hypertension', 'diabetes', 'underweight', 'osteoporosis',
  'gastric_ulcer', 'constipation', 'bloating', 'gerd',
  'skin_disease', 'allergic_rhinitis', 'joint_pain', 'gout',
];

const FLAGS_BY_CONDITION = {
  'woEO-woRAM': { hasEO: false, hasRAM: false },
  'wEO-woRAM':  { hasEO: true,  hasRAM: false },
  'woEO-wRAM':  { hasEO: false, hasRAM: true  },
  'wEO-wRAM':   { hasEO: true,  hasRAM: true  },
};

export function isConditionValid(c) {
  return typeof c === 'string' && VALID_CONDITIONS.includes(c);
}

function normalizeDisease(raw) {
  if (typeof raw !== 'string') return null;
  const key = raw.trim().toLowerCase().replace(/[\s-]+/g, '_');
  return VALID_DISEASES.includes(key) ? key : null;
}

const session = {
  /**
   * Called on app boot. Extracts uid from URL if present,
   * falls back to localStorage, then registers the session with the backend.
   * Returns the user_id string or null if none found.
   */
  async init() {
    const params     = new URLSearchParams(window.location.search);
    const urlUid     = params.get('uid');
    const urlCond    = params.get('condition');
    const urlDisease = params.get('disease');

    if (urlUid) {
      localStorage.setItem(USER_ID_KEY, urlUid);
      localStorage.setItem(ORIG_URL_KEY, window.location.href);
    }
    if (urlCond && isConditionValid(urlCond)) {
      localStorage.setItem(CONDITION_KEY, urlCond);
    }
    const normalizedDisease = normalizeDisease(urlDisease);
    if (normalizedDisease) {
      localStorage.setItem(DISEASE_KEY, normalizedDisease);
    }

    const userId = this.getUserId();
    if (!userId) return null;

    // Register (or resume) the session server-side
    try {
      const resp = await axios.post('/api/survey/session', {
        respondent_id:      userId,
        original_url: localStorage.getItem(ORIG_URL_KEY) || window.location.href,
        metadata: {
          user_agent:      navigator.userAgent,
          referrer:        document.referrer,
          viewport_width:  window.innerWidth,
          viewport_height: window.innerHeight,
          condition:       this.getCondition(),
          disease:         this.getDisease(),
        },
      });

      if (resp.data?.data?.share_url) {
        localStorage.setItem('survey_share_url', resp.data.data.share_url);
      }
    } catch (err) {
      console.warn('[session] Could not register session with backend:', err.message);
    }

    return userId;
  },

  getUserId() {
    return localStorage.getItem(USER_ID_KEY) || null;
  },

  getCondition() {
    return localStorage.getItem(CONDITION_KEY) || null;
  },

  getDisease() {
    return localStorage.getItem(DISEASE_KEY) || null;
  },

  getFlags() {
    const c = this.getCondition();
    if (!isConditionValid(c)) return null;
    return { condition: c, ...FLAGS_BY_CONDITION[c] };
  },

  getShareUrl() {
    return localStorage.getItem('survey_share_url') || null;
  },

  clear() {
    localStorage.removeItem(USER_ID_KEY);
    localStorage.removeItem(ORIG_URL_KEY);
    localStorage.removeItem(CONDITION_KEY);
    localStorage.removeItem(DISEASE_KEY);
    localStorage.removeItem('survey_share_url');
  },
};

export default session;
