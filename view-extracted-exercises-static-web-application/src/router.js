import { createRouter, createWebHashHistory } from "vue-router";

import CourseExercisesPage from "./views/CourseExercisesPage.vue";
import CoursesPage from "./views/CoursesPage.vue";
import ExerciseDetailPage from "./views/ExerciseDetailPage.vue";
import UploadPage from "./views/UploadPage.vue";

export function createAppRouter(store) {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/upload", name: "upload", component: UploadPage },
      { path: "/", name: "courses", component: CoursesPage },
      { path: "/courses/:courseId", name: "course", component: CourseExercisesPage, props: true },
      {
        path: "/courses/:courseId/exercises/:exerciseSlug",
        name: "exercise",
        component: ExerciseDetailPage,
        props: true
      }
    ]
  });

  router.beforeEach((to) => {
    if (!store.hasData.value && to.name !== "upload") {
      return { name: "upload" };
    }

    if (store.hasData.value && to.name === "upload") {
      return { name: "courses" };
    }

    return true;
  });

  return router;
}
