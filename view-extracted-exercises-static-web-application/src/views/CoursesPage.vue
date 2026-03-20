<script setup>
import { computed, inject, ref } from "vue";
import { RouterLink } from "vue-router";

import SearchField from "../components/SearchField.vue";

const store = inject("extractedDataStore");
const search = ref("");

const filteredCourses = computed(() => {
  const needle = search.value.trim().toLowerCase();
  const courses = store.normalized.value?.courses ?? [];

  if (!needle) {
    return courses;
  }

  return courses.filter((course) =>
    [course.name, course.description].some((value) => value?.toLowerCase().includes(needle))
  );
});
</script>

<template>
  <section class="space-y-6">
    <div class="panel p-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.3em] text-stone-500">Courses</p>
          <h2 class="mt-2 text-3xl font-semibold text-stone-900">Your extracted course archive</h2>
        </div>
        <div class="sm:w-96">
          <SearchField v-model="search" label="Search" placeholder="Search course name or description" />
        </div>
      </div>
    </div>

    <div class="panel overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full border-collapse">
          <thead class="bg-stone-100/80">
            <tr>
              <th class="table-head px-6 py-4">Course</th>
              <th class="table-head px-6 py-4">Description</th>
              <th class="table-head px-6 py-4">Exercises</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="course in filteredCourses" :key="course.id" class="border-t border-stone-200">
              <td class="px-6 py-5 align-top">
                <RouterLink
                  :to="{ name: 'course', params: { courseId: course.id } }"
                  class="text-lg font-semibold text-stone-900 underline decoration-stone-300 underline-offset-4 hover:decoration-stone-900"
                >
                  {{ course.name }}
                </RouterLink>
              </td>
              <td class="px-6 py-5 text-sm leading-7 text-stone-600">{{ course.description }}</td>
              <td class="px-6 py-5 text-sm text-stone-600">{{ course.exerciseCount }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>
</template>
