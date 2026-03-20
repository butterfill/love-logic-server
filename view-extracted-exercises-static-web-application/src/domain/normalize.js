import { createExerciseRecord } from "./renderers.js";

function makeExerciseSlug(exerciseId) {
  return encodeURIComponent(exerciseId);
}

export function normalizeExtractedDocument(document) {
  const courses = [];
  const exercisesBySlug = {};

  for (const course of document.courses ?? []) {
    const normalizedExerciseSetEntries = [];
    const exerciseEntries = [];

    for (const exerciseSet of course.exerciseSets ?? []) {
      for (const lecture of exerciseSet.lectures ?? []) {
        for (const unit of lecture.units ?? []) {
          for (const exercise of unit.exercises ?? []) {
            const slug = makeExerciseSlug(exercise.exerciseId);
            const exerciseRecord = createExerciseRecord({
              course,
              exerciseSet,
              lecture,
              unit,
              exercise
            });

            exerciseEntries.push(exerciseRecord);
            exercisesBySlug[slug] = exerciseRecord;
          }
        }
      }

      normalizedExerciseSetEntries.push({
        id: `${course.name}:${exerciseSet.variant}`,
        variant: exerciseSet.variant,
        description: exerciseSet.description,
        lectureCount: exerciseSet.lectures?.length ?? 0
      });
    }

    courses.push({
      id: encodeURIComponent(course.name),
      name: course.name,
      description: course.description,
      exerciseCount: exerciseEntries.length,
      exerciseSets: normalizedExerciseSetEntries,
      exercises: exerciseEntries
    });
  }

  return {
    uploadedAt: document.generatedAt ?? null,
    instructor: document.instructor ?? null,
    courseCount: courses.length,
    exerciseCount: Object.keys(exercisesBySlug).length,
    courses,
    exercisesBySlug
  };
}
