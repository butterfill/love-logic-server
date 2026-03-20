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
</script>

<template>
  <section v-if="course && lecture" class="space-y-6">
    <div class="panel p-6">
      <div class="text-xs uppercase tracking-[0.22em] text-stone-500">
        <RouterLink :to="{ name: 'courses' }" class="underline decoration-stone-300 underline-offset-4">Home</RouterLink>
        <span> / </span>
        <RouterLink :to="{ name: 'course', params: { courseId: course.id } }" class="underline decoration-stone-300 underline-offset-4">{{ course.name }}</RouterLink>
        <span> / {{ lecture.displayName }}</span>
      </div>

      <h2 class="mt-3 text-3xl font-semibold text-stone-900">{{ lecture.displayName }}</h2>
      <div class="mt-4 flex flex-wrap gap-2">
        <span class="chip">{{ lecture.exerciseSetVariant }}</span>
        <span class="chip">{{ lecture.exerciseCount }} questions</span>
      </div>
    </div>

    <div class="grid gap-4">
      <article v-for="section in lecture.sections" :key="section.id" class="panel p-5">
        <div class="flex items-center justify-between gap-4">
          <div>
            <h3 class="text-xl font-semibold text-stone-900">
              <RouterLink
                :to="{ name: 'section', params: { courseId: course.id, lectureId: lecture.id, sectionId: section.id } }"
                class="underline decoration-stone-300 underline-offset-4 hover:decoration-stone-900"
              >
                {{ section.displayName }}
              </RouterLink>
            </h3>
          </div>
          <span class="chip">{{ section.exerciseCount }} questions</span>
        </div>
      </article>
    </div>
  </section>
</template>
