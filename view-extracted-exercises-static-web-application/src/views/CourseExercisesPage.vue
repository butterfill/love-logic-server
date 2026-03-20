<script setup>
import { computed, inject, ref } from "vue";
import { RouterLink, useRoute } from "vue-router";

import SearchField from "../components/SearchField.vue";

const store = inject("extractedDataStore");
const route = useRoute();
const search = ref("");
const selectedBadges = ref([]);
const answeredOnly = ref(false);

const course = computed(() =>
  store.normalized.value?.courses.find((item) => item.id === route.params.courseId) ?? null
);

const availableBadges = computed(() => {
  const counts = new Map();
  for (const exercise of course.value?.exercises ?? []) {
    for (const badge of exercise.badges ?? []) {
      counts.set(badge, (counts.get(badge) ?? 0) + 1);
    }
  }
  return [...counts.entries()]
    .sort((left, right) => left[0].localeCompare(right[0]))
    .map(([label, count]) => ({ label, count }));
});

const filteredExercises = computed(() => {
  const exercises = course.value?.exercises ?? [];
  const needle = search.value.trim().toLowerCase();

  return exercises.filter((exercise) => {
    const matchesSearch =
      !needle ||
      [
        exercise.exerciseId,
        exercise.type,
        exercise.lectureName,
        exercise.unitName,
        exercise.question.title,
        exercise.question.prose,
        ...(exercise.badges ?? [])
      ]
        .filter(Boolean)
        .some((value) => value.toLowerCase().includes(needle));

    const matchesBadges =
      selectedBadges.value.length === 0 ||
      selectedBadges.value.every((badge) => exercise.badges?.includes(badge));

    const matchesAnsweredOnly = !answeredOnly.value || exercise.answerCount > 0;

    return matchesSearch && matchesBadges && matchesAnsweredOnly;
  });
});

const totalExercises = computed(() => course.value?.exercises.length ?? 0);

function toggleBadge(label) {
  if (selectedBadges.value.includes(label)) {
    selectedBadges.value = selectedBadges.value.filter((badge) => badge !== label);
    return;
  }
  selectedBadges.value = [...selectedBadges.value, label];
}
</script>

<template>
  <section v-if="course" class="space-y-6">
    <div class="panel p-6">
      <div class="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <RouterLink
            :to="{ name: 'course', params: { courseId: course.id } }"
            class="text-xs uppercase tracking-[0.22em] text-stone-500 underline decoration-stone-300 underline-offset-4"
          >
            {{ course?.name }}
          </RouterLink>
          <h2 class="mt-2 text-3xl font-semibold text-stone-900">all exercises for this course</h2>
          <p class="mt-3 max-w-3xl text-sm leading-7 text-stone-600">{{ course.description }}</p>
        </div>
        <div class="sm:w-96">
          <SearchField v-model="search" label="Search" placeholder="Search exercise id, type, lecture or unit" />
        </div>
      </div>

      <div class="mt-6 border-t border-stone-200 pt-5">
        <div class="flex flex-wrap items-center gap-3">
          <button
            class="rounded-full border px-4 py-2 text-sm font-medium transition"
            :class="answeredOnly ? 'border-stone-900 bg-stone-900 text-white' : 'border-stone-300 bg-stone-50 text-stone-700'"
            @click="answeredOnly = !answeredOnly"
          >
            Answers only
          </button>

          <button
            v-for="badge in availableBadges"
            :key="badge.label"
            class="rounded-full border px-4 py-2 text-sm font-medium transition"
            :class="
              selectedBadges.includes(badge.label)
                ? 'border-stone-900 bg-stone-900 text-white'
                : 'border-stone-300 bg-white text-stone-700 hover:border-stone-500'
            "
            @click="toggleBadge(badge.label)"
          >
            {{ badge.label }} · {{ badge.count }}
          </button>
        </div>
      </div>
    </div>

    <div class="px-1 text-sm text-stone-600">
      displaying {{ filteredExercises.length }} of {{ totalExercises }}
    </div>

    <div class="grid gap-4">
      <article v-for="exercise in filteredExercises" :key="exercise.slug" class="panel p-5">
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
                    lectureId: encodeURIComponent(exercise.lectureName),
                    sectionId: encodeURIComponent(exercise.unitName),
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
