import { createRouter, createWebHistory } from 'vue-router';
import EntryPage from '../pages/EntryPage.vue';
import SusceptibilityPage from '../pages/SusceptibilityPage.vue';
import SeverityPage from '../pages/SeverityPage.vue';
import EfficacyPage from '../pages/EfficacyPage.vue';
import DoctorPreferencePage from '../pages/DoctorPreferencePage.vue';
import DoctorRecommendationPage from '../pages/DoctorRecommendationPage.vue';
import ConsultationReminderPage from '../pages/ConsultationReminderPage.vue';
import PracticePage from '../pages/PracticePage.vue';
import SurveyPage from '../pages/SurveyPage.vue';
import SummaryPage from '../pages/SummaryPage.vue';
import DeviceBlockPage from '../pages/DeviceBlockPage.vue';
import NotFound from '../pages/404.vue';
import session, { isConditionValid } from '../lib/session';
import { isMobileOrTablet } from '../lib/device';

const CONDITION_PROTECTED = [
  'Susceptibility', 'Severity', 'Efficacy',
  'DoctorPreference', 'DoctorRecommendation', 'ConsultationReminder',
  'Practice', 'Survey', 'Summary',
];

// Each route's predecessor flag in sessionStorage. If the flag is missing,
// the router redirects back to the page that owns it, ensuring users move
// through the framing content in order.
const SEQUENCE_GATE = {
  Susceptibility:       { flag: 'practice_done',               fallback: 'Practice'             },
  Severity:             { flag: 'susceptibility_done',         fallback: 'Susceptibility'       },
  Efficacy:             { flag: 'severity_done',               fallback: 'Severity'             },
  DoctorPreference:     { flag: 'efficacy_done',               fallback: 'Efficacy'             },
  DoctorRecommendation: { flag: 'doctor_preference_done',      fallback: 'DoctorPreference'     },
  ConsultationReminder: { flag: 'doctor_recommendation_done',  fallback: 'DoctorRecommendation' },
  Survey:               { flag: 'consultation_reminder_done',  fallback: 'ConsultationReminder' },
};

const routes = [
  { path: '/',                       name: 'Entry',                component: EntryPage },
  { path: '/susceptibility',         name: 'Susceptibility',       component: SusceptibilityPage },
  { path: '/severity',               name: 'Severity',             component: SeverityPage },
  { path: '/efficacy',               name: 'Efficacy',             component: EfficacyPage },
  { path: '/doctor-preference',      name: 'DoctorPreference',     component: DoctorPreferencePage },
  { path: '/doctor-recommendation',  name: 'DoctorRecommendation', component: DoctorRecommendationPage },
  { path: '/consultation-reminder',  name: 'ConsultationReminder', component: ConsultationReminderPage },
  { path: '/practice',               name: 'Practice',             component: PracticePage },
  { path: '/survey',                 name: 'Survey',               component: SurveyPage },
  { path: '/summary',                name: 'Summary',              component: SummaryPage },
  { path: '/device-block',           name: 'DeviceBlock',          component: DeviceBlockPage },
  { path: '/invalid',                name: 'Invalid',              component: NotFound },
  { path: '/:pathMatch(.*)*',        name: 'NotFound',             component: NotFound },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to) => {
  // Device gate: keep phones/tablets out of the entire survey flow.
  if (to.name !== 'DeviceBlock' && isMobileOrTablet()) {
    return { name: 'DeviceBlock' };
  }

  // Condition gate: every survey-flow route must resolve to a valid condition,
  // either fresh in the URL or previously stored in localStorage. An invalid
  // ?condition in the URL (e.g. an unsubstituted placeholder appended by an
  // external survey tool's redirect) is ignored in favour of the stored one.
  if (CONDITION_PROTECTED.includes(to.name)) {
    const urlCond = to.query.condition;
    const effective = isConditionValid(urlCond) ? urlCond : session.getCondition();
    if (!isConditionValid(effective)) {
      return { name: 'Invalid' };
    }
  }

  // Sequential gate: enforce the framing pages are read in order.
  const gate = SEQUENCE_GATE[to.name];
  if (gate && !sessionStorage.getItem(gate.flag)) {
    return { name: gate.fallback, query: to.query };
  }

  if (to.name === 'Summary' && !sessionStorage.getItem('survey_answers_v1')) {
    return { name: 'Survey', query: to.query };
  }
});

export default router;
