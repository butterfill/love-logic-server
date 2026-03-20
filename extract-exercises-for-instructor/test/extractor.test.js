import { describe, expect, it } from "vitest";

import {
  buildInstructorExport,
  findUserByEmailAddress,
  normalizeMongoUrl
} from "../src/extractor.js";

describe("findUserByEmailAddress", () => {
  it("matches an email address case-insensitively", () => {
    const users = [
      { _id: "u1", emails: [{ address: "teacher@example.com" }] },
      { _id: "u2", emails: [{ address: "someone@example.com" }] }
    ];

    expect(findUserByEmailAddress(users, "Teacher@Example.com")).toEqual(users[0]);
  });

  it("returns null when no user matches", () => {
    expect(findUserByEmailAddress([], "missing@example.com")).toBeNull();
  });
});

describe("buildInstructorExport", () => {
  it("includes only courses, exercise sets, and answers owned by the requested instructor", () => {
    const exportData = buildInstructorExport({
      instructor: {
        _id: "instructor-1",
        emails: [{ address: "teacher@example.com" }],
        profile: { name: "Teacher", is_instructor: true }
      },
      courses: [
        { _id: "course-1", name: "logic-101", description: "Logic 101" },
        { _id: "course-2", name: "other-course", description: "Other" }
      ],
      exerciseSets: [
        {
          _id: "set-1",
          owner: "instructor-1",
          courseName: "logic-101",
          variant: "normal",
          description: "Main set",
          lectures: [
            {
              name: "lecture_01",
              units: [
                {
                  name: "unit-1",
                  rawReading: ["1.1"],
                  rawExercises: ["/ex/proof/1", "/ex/proof/2"]
                }
              ]
            }
          ]
        },
        {
          _id: "set-2",
          owner: "other-user",
          courseName: "other-course",
          variant: "fast",
          description: "Other set",
          lectures: [
            {
              name: "lecture_02",
              units: [{ name: "unit-2", rawExercises: ["/ex/proof/3"] }]
            }
          ]
        }
      ],
      submissions: [
        {
          _id: "submission-1",
          owner: "instructor-1",
          exerciseId: "/ex/proof/1",
          answer: { content: { proof: "A" } }
        },
        {
          _id: "submission-2",
          owner: "student-2",
          exerciseId: "/ex/proof/2",
          answer: { content: { proof: "B" } }
        },
        {
          _id: "submission-3",
          owner: "student-3",
          exerciseId: "/ex/proof/3",
          answer: { content: { proof: "C" } }
        }
      ]
    });

    expect(exportData.instructor.emailAddress).toBe("teacher@example.com");
    expect(exportData.courses).toHaveLength(1);
    expect(exportData.courses[0].name).toBe("logic-101");
    expect(exportData.courses[0].exerciseSets).toHaveLength(1);
    expect(exportData.courses[0].exerciseSets[0].lectures[0].units[0].exercises).toEqual([
      {
        exerciseId: "/ex/proof/1",
        answers: [
          {
            _id: "submission-1",
            owner: "instructor-1",
            exerciseId: "/ex/proof/1",
            answer: { content: { proof: "A" } }
          }
        ]
      },
      {
        exerciseId: "/ex/proof/2",
        answers: []
      }
    ]);
  });

  it("does not include answers owned by other users even when the exercise is owned by the instructor", () => {
    const exportData = buildInstructorExport({
      instructor: {
        _id: "instructor-1",
        emails: [{ address: "teacher@example.com" }]
      },
      courses: [{ _id: "course-1", name: "logic-101", description: "Logic 101" }],
      exerciseSets: [
        {
          _id: "set-1",
          owner: "instructor-1",
          courseName: "logic-101",
          variant: "normal",
          description: "Main set",
          lectures: [
            {
              name: "lecture_01",
              units: [{ name: "unit-1", rawExercises: ["/ex/proof/1"] }]
            }
          ]
        }
      ],
      submissions: [
        { _id: "submission-1", owner: "other-user", exerciseId: "/ex/proof/1" },
        { _id: "submission-2", exerciseId: "/ex/proof/other" }
      ]
    });

    expect(exportData.exerciseIds).toEqual(["/ex/proof/1"]);
    expect(exportData.courses[0].exerciseSets[0].lectures[0].units[0].exercises[0].answers).toEqual([]);
  });
});

describe("normalizeMongoUrl", () => {
  it("forces directConnection for a single loopback SSH-forwarded host", () => {
    expect(
      normalizeMongoUrl("mongodb://root:pw@127.0.0.1:27018/db?authSource=admin")
    ).toBe("mongodb://root:pw@127.0.0.1:27018/db?authSource=admin&directConnection=true");
  });

  it("does not change a URL that already specifies directConnection", () => {
    expect(
      normalizeMongoUrl("mongodb://root:pw@127.0.0.1:27018/db?authSource=admin&directConnection=false")
    ).toBe("mongodb://root:pw@127.0.0.1:27018/db?authSource=admin&directConnection=false");
  });

  it("can be controlled explicitly through an option", () => {
    expect(
      normalizeMongoUrl("mongodb://db.example.com:27017/love-logic", { directConnection: true })
    ).toBe("mongodb://db.example.com:27017/love-logic?directConnection=true");
  });
});
