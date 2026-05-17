import { createRouter, createWebHistory } from 'vue-router';
import PracticePage from '../pages/PracticePage.vue';
import SurveyPage from '../pages/SurveyPage.vue';
import SummaryPage from '../pages/SummaryPage.vue';
import DeviceBlockPage from '../pages/DeviceBlockPage.vue';
import NotFound from '../pages/404.vue';
import session, { isConditionValid } from '../lib/session';
import { isMobileOrTablet } from '../lib/device';

const CONDITION_PROTECTED = ['Practice', 'Survey', 'Summary'];

const routes = [
  {
    path: '/practice',
    name: 'Practice',
    component: PracticePage,
  },
  {
    path: '/survey',
    name: 'Survey',
    component: SurveyPage,
  },
  {
    path: '/summary',
    name: 'Summary',
    component: SummaryPage,
  },
  {
    path: '/',
    redirect: '/practice',
  },
  {
    path: '/device-block',
    name: 'DeviceBlock',
    component: DeviceBlockPage,
  },
  {
    path: '/invalid',
    name: 'Invalid',
    component: NotFound,
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: NotFound,
  },
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

  // Condition gate: every survey-flow route must have a valid ?condition,
  // either fresh in the URL or previously stored in localStorage.
  if (CONDITION_PROTECTED.includes(to.name)) {
    const urlCond = to.query.condition;
    if (urlCond !== undefined && !isConditionValid(urlCond)) {
      return { name: 'Invalid' };
    }
    const effective = urlCond ?? session.getCondition();
    if (!isConditionValid(effective)) {
      return { name: 'Invalid' };
    }
  }

  if (to.name === 'Survey' && !localStorage.getItem('survey_practice_done')) {
    return { name: 'Practice', query: to.query };
  }
  if (to.name === 'Summary' && !sessionStorage.getItem('survey_answers_v1')) {
    return { name: 'Survey', query: to.query };
  }
});

export default router;
