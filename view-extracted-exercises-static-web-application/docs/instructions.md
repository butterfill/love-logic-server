Your next task is to design and create a static web application. 
The source will live in ./view-extracted-exercises-static-web-application

It will use pnpm, vue, tailwindcss and vitest.

The purpose of the web application is to enable the instructor to view and search their own courses, exercises and answers.

The user will upload a .json file that was created with the `extract-exercises-for-instructor` tool. This data will be stored in their web browser so that they do not have to re-upload it. 

After uploading, the web application will show the opening view: a search box and a table listing all courses. When the user clicks on a course, they will see a list of exercises for that course. When they click on an exercise, they will see their answers for that exercise. This view also contains the 'clear data' button: this pops up a modal for confirmation, then (if confirmed) removes all stored data so that the user can re-upload.

Ensure that the views for each item are bookmarkable so that the user can easily return to them.

Displaying the questions is difficult. Your aim here is to display them in the same way that the meteor application in love-logic-server/ does. To this end, you can use the @butterfill@awfol library . This library is documented in docs/README-awfol-library-AGENTS.md . (It is the same code that the meteor application uses, just packaged as an ESM module with ts interfaces.)

Good design is critical.  For example, the logic for generating the representations of each question type should be clearly separated, easy to work on independently of any UI code, and easy to re-use.

Use green+red TDD.

Carefully document key architectural decisions. Also provide a README.md explaining how to deploy the static application using surge.sh and cloudflare pages (assume wrangler CLI is installed).

Ask me any questions to which you need the answers before starting.
