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
    const lecturesById = {};
    const lectureOrder = [];

    for (const exerciseSet of course.exerciseSets ?? []) {
      for (const lecture of exerciseSet.lectures ?? []) {
        const lectureId = encodeURIComponent(lecture.name);
        if (!lecturesById[lectureId]) {
          lecturesById[lectureId] = {
            id: lectureId,
            name: lecture.name,
            displayName: humanizeLectureName(lecture.name),
            exerciseSetVariant: exerciseSet.variant,
            sections: []
          };
          lectureOrder.push(lectureId);
        }

        for (const unit of lecture.units ?? []) {
          const sectionId = encodeURIComponent(unit.name);
          const sectionExercises = [];

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
            sectionExercises.push(exerciseRecord);
            exercisesBySlug[slug] = exerciseRecord;
          }

          lecturesById[lectureId].sections.push({
            id: sectionId,
            name: unit.name,
            displayName: unit.name,
            exerciseCount: sectionExercises.length,
            exercises: sectionExercises
          });
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
      lectures: lectureOrder.map((lectureId) => ({
        ...lecturesById[lectureId],
        sectionCount: lecturesById[lectureId].sections.length,
        exerciseCount: lecturesById[lectureId].sections.reduce(
          (count, section) => count + section.exerciseCount,
          0
        )
      })),
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

function humanizeLectureName(name) {
  const match = String(name).match(/^lecture[_\-\s]?0*([0-9]+)$/i);
  if (match) {
    return `Lecture ${match[1]}`;
  }
  return String(name).replace(/_/g, " ");
}
