<script setup>
import { computed, inject, ref } from "vue";
import { RouterLink, useRoute } from "vue-router";

import SearchField from "../components/SearchField.vue";

const store = inject("extractedDataStore");
const route = useRoute();
const search = ref("");

const course = computed(() =>
  store.normalized.value?.courses.find((item) => item.id === route.params.courseId) ?? null
);

const filteredExercises = computed(() => {
  const exercises = course.value?.exercises ?? [];
  const needle = search.value.trim().toLowerCase();

  if (!needle) {
    return exercises;
  }

  return exercises.filter((exercise) =>
    [
      exercise.exerciseId,
      exercise.type,
      exercise.lectureName,
      exercise.unitName,
      exercise.question.title,
      exercise.question.prose
    ]
      .filter(Boolean)
      .some((value) => value.toLowerCase().includes(needle))
  );
});
</script>

<template>
  <section v-if="course" class="space-y-6">
    <div class="panel p-6">
      <div class="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <RouterLink
            :to="{ name: 'courses' }"
            class="text-xs uppercase tracking-[0.22em] text-stone-500 underline decoration-stone-300 underline-offset-4"
          >
            All courses
          </RouterLink>
          <h2 class="mt-2 text-3xl font-semibold text-stone-900">{{ course.name }}</h2>
          <p class="mt-3 max-w-3xl text-sm leading-7 text-stone-600">{{ course.description }}</p>
        </div>
        <div class="sm:w-96">
          <SearchField v-model="search" label="Search" placeholder="Search exercise id, type, lecture or unit" />
        </div>
      </div>
    </div>

    <div class="grid gap-4">
      <article v-for="exercise in filteredExercises" :key="exercise.slug" class="panel p-5">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div class="flex flex-wrap gap-2">
              <span class="chip">{{ exercise.type }}</span>
              <span class="chip">{{ exercise.exerciseSetVariant }}</span>
              <span class="chip">{{ exercise.lectureName }}</span>
              <span class="chip">{{ exercise.unitName }}</span>
            </div>
            <h3 class="mt-4 text-xl font-semibold text-stone-900">
              <RouterLink
                :to="{ name: 'exercise', params: { courseId: course.id, exerciseSlug: exercise.slug } }"
                class="underline decoration-stone-300 underline-offset-4 hover:decoration-stone-900"
              >
                {{ exercise.question.title }}
              </RouterLink>
            </h3>
            <p class="mt-2 break-all text-sm leading-7 text-stone-600">{{ exercise.exerciseId }}</p>
          </div>
          <div class="text-sm text-stone-500">{{ exercise.answerCount }} answer<span v-if="exercise.answerCount !== 1">s</span></div>
        </div>
      </article>
    </div>
  </section>
</template>
