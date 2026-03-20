import { MongoClient } from "mongodb";

const DEFAULT_MONGODB_URL = "mongodb://localhost:27017/love-logic";

function normalizeEmailAddress(emailAddress) {
  return String(emailAddress).trim().toLowerCase();
}

function getPrimaryEmailAddress(user) {
  return user?.emails?.[0]?.address ?? null;
}

function cloneForJson(value) {
  return JSON.parse(JSON.stringify(value));
}

export function findUserByEmailAddress(users, emailAddress) {
  const wantedEmailAddress = normalizeEmailAddress(emailAddress);

  return (
    users.find((user) =>
      user.emails?.some((email) => normalizeEmailAddress(email.address) === wantedEmailAddress)
    ) ?? null
  );
}

export function buildInstructorExport({ instructor, courses, exerciseSets, submissions }) {
  const ownedExerciseSets = exerciseSets.filter((exerciseSet) => exerciseSet.owner === instructor._id);
  const courseNames = [...new Set(ownedExerciseSets.map((exerciseSet) => exerciseSet.courseName))];
  const ownedCourses = courses.filter((course) => courseNames.includes(course.name));
  const submissionMap = new Map();
  const exerciseIdSet = new Set();

  for (const submission of submissions) {
    const existing = submissionMap.get(submission.exerciseId) ?? [];
    existing.push(cloneForJson(submission));
    submissionMap.set(submission.exerciseId, existing);
  }

  for (const exerciseSet of ownedExerciseSets) {
    for (const lecture of exerciseSet.lectures ?? []) {
      for (const unit of lecture.units ?? []) {
        for (const exerciseId of unit.rawExercises ?? []) {
          exerciseIdSet.add(exerciseId);
        }
      }
    }
  }

  return {
    generatedAt: new Date().toISOString(),
    instructor: {
      _id: instructor._id,
      emailAddress: getPrimaryEmailAddress(instructor),
      profile: cloneForJson(instructor.profile ?? {})
    },
    exerciseIds: [...exerciseIdSet].sort(),
    courses: ownedCourses
      .map((course) => ({
        ...cloneForJson(course),
        exerciseSets: ownedExerciseSets
          .filter((exerciseSet) => exerciseSet.courseName === course.name)
          .map((exerciseSet) => ({
            ...cloneForJson(exerciseSet),
            lectures: (exerciseSet.lectures ?? []).map((lecture) => ({
              ...cloneForJson(lecture),
              units: (lecture.units ?? []).map((unit) => ({
                ...cloneForJson(unit),
                exercises: (unit.rawExercises ?? []).map((exerciseId) => ({
                  exerciseId,
                  answers: submissionMap.get(exerciseId) ?? []
                }))
              }))
            }))
          }))
      }))
      .sort((left, right) => left.name.localeCompare(right.name))
  };
}

export async function extractInstructorData(emailAddress, options = {}) {
  const mongoUrl =
    options.mongoUrl ??
    process.env.EXTRACTOR_MONGODB_URL ??
    process.env.MONGODB_URL ??
    process.env.MONGO_URL ??
    DEFAULT_MONGODB_URL;

  const client = options.client ?? new MongoClient(mongoUrl);
  const shouldCloseClient = !options.client;

  try {
    await client.connect();

    const db = client.db();
    const users = db.collection("users");
    const courses = db.collection("courses");
    const exerciseSets = db.collection("exercise_sets");
    const submissions = db.collection("submitted_exercises");

    const instructor =
      (await users.findOne({
        "emails.address": { $regex: `^${escapeRegExp(emailAddress)}$`, $options: "i" }
      })) ?? null;

    if (!instructor) {
      throw new Error(`No user found for email address: ${emailAddress}`);
    }

    const ownedExerciseSets = await exerciseSets.find({ owner: instructor._id }).toArray();
    const ownedExerciseIds = [...collectExerciseIds(ownedExerciseSets)];
    const ownedCourseNames = [...new Set(ownedExerciseSets.map((exerciseSet) => exerciseSet.courseName))];

    const [ownedCourses, matchingSubmissions] = await Promise.all([
      courses.find({ name: { $in: ownedCourseNames } }).toArray(),
      ownedExerciseIds.length === 0
        ? []
        : submissions.find({ exerciseId: { $in: ownedExerciseIds } }).toArray()
    ]);

    return buildInstructorExport({
      instructor,
      courses: ownedCourses,
      exerciseSets: ownedExerciseSets,
      submissions: matchingSubmissions
    });
  } finally {
    if (shouldCloseClient) {
      await client.close();
    }
  }
}

function collectExerciseIds(exerciseSets) {
  const exerciseIds = new Set();

  for (const exerciseSet of exerciseSets) {
    for (const lecture of exerciseSet.lectures ?? []) {
      for (const unit of lecture.units ?? []) {
        for (const exerciseId of unit.rawExercises ?? []) {
          exerciseIds.add(exerciseId);
        }
      }
    }
  }

  return exerciseIds;
}

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
