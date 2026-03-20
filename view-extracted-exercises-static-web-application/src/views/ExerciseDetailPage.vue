<script setup>
import { computed, inject, ref } from "vue";
import { RouterLink, useRoute } from "vue-router";

import AnswerCard from "../components/AnswerCard.vue";
import QuestionRenderer from "../components/QuestionRenderer.vue";
import SearchField from "../components/SearchField.vue";

const store = inject("extractedDataStore");
const route = useRoute();
const search = ref("");

const exercise = computed(
  () => store.normalized.value?.exercisesBySlug[route.params.exerciseSlug] ?? null
);

const course = computed(() =>
  store.normalized.value?.courses.find((item) => item.id === route.params.courseId) ?? null
);

const lecture = computed(() =>
  course.value?.lectures.find((item) => item.id === route.params.lectureId) ?? null
);

const section = computed(() =>
  lecture.value?.sections.find((item) => item.id === route.params.sectionId) ?? null
);

const filteredAnswers = computed(() => {
  const answers = exercise.value?.answers ?? [];
  const needle = search.value.trim().toLowerCase();

  if (!needle) {
    return answers;
  }

  return answers.filter((answer) =>
    JSON.stringify(answer).toLowerCase().includes(needle)
  );
});
</script>

<template>
  <section v-if="exercise && course && lecture && section" class="space-y-6">
    <div class="panel p-6">
      <div class="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <div class="text-xs uppercase tracking-[0.22em] text-stone-500">
            <RouterLink :to="{ name: 'courses' }" class="underline decoration-stone-300 underline-offset-4">Home</RouterLink>
            <span> / </span>
            <RouterLink :to="{ name: 'course', params: { courseId: course.id } }" class="underline decoration-stone-300 underline-offset-4">{{ course.name }}</RouterLink>
            <span> / </span>
            <RouterLink :to="{ name: 'lecture', params: { courseId: course.id, lectureId: lecture.id } }" class="underline decoration-stone-300 underline-offset-4">{{ lecture.displayName }}</RouterLink>
            <span> / </span>
            <RouterLink
              :to="{ name: 'section', params: { courseId: course.id, lectureId: lecture.id, sectionId: section.id } }"
              class="underline decoration-stone-300 underline-offset-4"
            >
              {{ section.displayName }}
            </RouterLink>
            <span> / questions / question</span>
          </div>
          <h2 class="mt-2 break-all text-3xl font-semibold text-stone-900">{{ exercise.exerciseId }}</h2>
          <div class="mt-3 flex flex-wrap gap-2">
            <span class="chip">{{ exercise.type }}</span>
            <span class="chip">{{ exercise.exerciseSetVariant }}</span>
            <span class="chip">{{ exercise.lectureName }}</span>
            <span class="chip">{{ exercise.unitName }}</span>
          </div>
        </div>
        <div class="sm:w-96">
          <SearchField v-model="search" label="Search" placeholder="Search within stored answers and feedback" />
        </div>
      </div>
    </div>

    <QuestionRenderer :question="exercise.question" />

    <section class="space-y-4">
      <div class="flex items-center justify-between">
        <h3 class="text-xl font-semibold text-stone-900">Answers</h3>
        <p class="text-sm text-stone-500">{{ filteredAnswers.length }} shown</p>
      </div>

      <p v-if="filteredAnswers.length === 0" class="panel p-6 text-sm leading-7 text-stone-600">
        No stored answers match this filter.
      </p>

      <AnswerCard v-for="answer in filteredAnswers" :key="answer._id ?? JSON.stringify(answer)" :answer="answer" />
    </section>
  </section>
</template>
