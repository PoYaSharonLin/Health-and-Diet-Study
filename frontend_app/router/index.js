import { createRouter, createWebHistory } from 'vue-router';
import PracticePage from '../pages/PracticePage.vue';
import SurveyPage from '../pages/SurveyPage.vue';
import SummaryPage from '../pages/SummaryPage.vue';
import PostSurvey from '../pages/PostSurvey.vue';
import NotFound from '../pages/404.vue';

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
    path: '/postsurvey',
    name: 'PostSurvey',
    component: PostSurvey,
  },
  {
    path: '/',
    redirect: '/practice',
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

// Guard: anyone who opens /survey directly is sent to /practice first,
// unless they already confirmed the practice question in this browser.
router.beforeEach((to) => {
  if (to.name === 'Survey' && !localStorage.getItem('survey_practice_done')) {
    return { name: 'Practice', query: to.query };
  }
  if (to.name === 'Summary' && !sessionStorage.getItem('survey_answers_v1')) {
    return { name: 'Survey', query: to.query };
  }
  if (to.name === 'PostSurvey' && !sessionStorage.getItem('survey_answers_v1')) {
    return { name: 'Survey', query: to.query };
  }
});

export default router;
