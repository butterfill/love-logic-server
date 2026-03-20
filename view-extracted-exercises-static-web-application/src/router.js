import { createRouter, createWebHashHistory } from "vue-router";

import CourseHomePage from "./views/CourseHomePage.vue";
import CourseExercisesPage from "./views/CourseExercisesPage.vue";
import CoursesPage from "./views/CoursesPage.vue";
import ExerciseDetailPage from "./views/ExerciseDetailPage.vue";
import LecturePage from "./views/LecturePage.vue";
import SectionPage from "./views/SectionPage.vue";
import UploadPage from "./views/UploadPage.vue";

export function createAppRouter(store) {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/upload", name: "upload", component: UploadPage },
      { path: "/", name: "courses", component: CoursesPage },
      { path: "/course/:courseId", name: "course", component: CourseHomePage, props: true },
      { path: "/course/:courseId/all", name: "course-all", component: CourseExercisesPage, props: true },
      {
        path: "/course/:courseId/lecture/:lectureId",
        name: "lecture",
        component: LecturePage,
        props: true
      },
      {
        path: "/course/:courseId/lecture/:lectureId/section/:sectionId",
        name: "section",
        component: SectionPage,
        props: true
      },
      {
        path: "/course/:courseId/lecture/:lectureId/section/:sectionId/question/:exerciseSlug",
        name: "exercise",
        component: ExerciseDetailPage,
        props: true
      },
      {
        path: "/courses/:courseId",
        redirect: (to) => ({ name: "course-all", params: { courseId: to.params.courseId } })
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
