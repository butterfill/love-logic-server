<script setup>
import { computed, inject } from "vue";
import { RouterLink, useRoute } from "vue-router";

const store = inject("extractedDataStore");
const route = useRoute();

const course = computed(() =>
  store.normalized.value?.courses.find((item) => item.id === route.params.courseId) ?? null
);
</script>

<template>
  <section v-if="course" class="space-y-6">
    <div class="panel p-6">
      <RouterLink
        :to="{ name: 'courses' }"
        class="text-xs uppercase tracking-[0.22em] text-stone-500 underline decoration-stone-300 underline-offset-4"
      >
        Home
      </RouterLink>
      <h2 class="mt-3 text-3xl font-semibold text-stone-900">{{ course.name }}</h2>
      <p class="mt-3 max-w-3xl text-sm leading-7 text-stone-600">{{ course.description }}</p>
      <div class="mt-5">
        <RouterLink
          :to="{ name: 'course-all', params: { courseId: course.id } }"
          class="rounded-full border border-stone-300 bg-stone-50 px-4 py-2 text-sm font-medium text-stone-700 transition hover:border-stone-900 hover:bg-white"
        >
          all exercises for this course
        </RouterLink>
      </div>
    </div>

    <div class="grid gap-4">
      <article v-for="lecture in course.lectures" :key="lecture.id" class="panel p-5">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <h3 class="text-2xl font-semibold text-stone-900">
              <RouterLink
                :to="{ name: 'lecture', params: { courseId: course.id, lectureId: lecture.id } }"
                class="underline decoration-stone-300 underline-offset-4 hover:decoration-stone-900"
              >
                {{ lecture.displayName }}
              </RouterLink>
            </h3>
            <ul class="mt-4 space-y-2">
              <li v-for="section in lecture.sections" :key="section.id" class="text-sm text-stone-700">
                <RouterLink
                  :to="{
                    name: 'section',
                    params: { courseId: course.id, lectureId: lecture.id, sectionId: section.id }
                  }"
                  class="underline decoration-stone-300 underline-offset-4 hover:decoration-stone-900"
                >
                  {{ section.displayName }}
                </RouterLink>
                <span class="ml-2 text-stone-500">({{ section.exerciseCount }})</span>
              </li>
            </ul>
          </div>
          <div class="flex flex-wrap gap-2 text-sm text-stone-500">
            <span class="chip">{{ lecture.exerciseSetVariant }}</span>
            <span class="chip">{{ lecture.sectionCount }} sections</span>
            <span class="chip">{{ lecture.exerciseCount }} questions</span>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>
