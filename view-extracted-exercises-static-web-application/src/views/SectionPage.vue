<script setup>
import { computed, inject } from "vue";
import { RouterLink, useRoute } from "vue-router";

const store = inject("extractedDataStore");
const route = useRoute();

const course = computed(() =>
  store.normalized.value?.courses.find((item) => item.id === route.params.courseId) ?? null
);

const lecture = computed(() =>
  course.value?.lectures.find((item) => item.id === route.params.lectureId) ?? null
);

const section = computed(() =>
  lecture.value?.sections.find((item) => item.id === route.params.sectionId) ?? null
);
</script>

<template>
  <section v-if="course && lecture && section" class="space-y-6">
    <div class="panel p-6">
      <div class="text-xs uppercase tracking-[0.22em] text-stone-500">
        <RouterLink :to="{ name: 'courses' }" class="underline decoration-stone-300 underline-offset-4">Home</RouterLink>
        <span> / </span>
        <RouterLink :to="{ name: 'course', params: { courseId: course.id } }" class="underline decoration-stone-300 underline-offset-4">{{ course.name }}</RouterLink>
        <span> / </span>
        <RouterLink :to="{ name: 'lecture', params: { courseId: course.id, lectureId: lecture.id } }" class="underline decoration-stone-300 underline-offset-4">{{ lecture.displayName }}</RouterLink>
        <span> / {{ section.displayName }}</span>
      </div>

      <h2 class="mt-3 text-3xl font-semibold text-stone-900">{{ section.displayName }}</h2>
      <p class="mt-3 text-sm text-stone-600">questions</p>
    </div>

    <div class="grid gap-4">
      <article v-for="exercise in section.exercises" :key="exercise.slug" class="panel p-5">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div class="flex flex-wrap gap-2">
              <span v-for="badge in exercise.badges" :key="badge" class="chip">{{ badge }}</span>
            </div>
            <h3 class="mt-4 text-xl font-semibold text-stone-900">
              <RouterLink
                :to="{
                  name: 'exercise',
                  params: {
                    courseId: course.id,
                    lectureId: lecture.id,
                    sectionId: section.id,
                    exerciseSlug: exercise.slug
                  }
                }"
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
