# view-extracted-exercises-static-web-application

Static Vue application for viewing the JSON archives produced by `extract-exercises-for-instructor`.

## Stack

- `pnpm`
- `vue`
- `vue-router`
- `tailwindcss`
- `vitest`
- `@butterfill/awfol`

## Install

```bash
pnpm install
```

If your shell has not set `NODE_AUTH_TOKEN`, install with one available because `@butterfill/awfol` is pulled from GitHub Packages.

## Develop

```bash
pnpm dev
```

## Test

```bash
pnpm test
```

## Build

```bash
pnpm build
```

The production files are written to `dist/`.

## Application flow

1. Open the app.
2. Upload a `.json` file created by `extract-exercises-for-instructor`.
3. The file is saved in browser storage.
4. Browse searchable courses on the home page.
5. Open a course to browse a lecture-and-section table of contents.
6. Open a lecture, then a section, then a question.
7. Open `/course/<course-id>/all` for the flat list labelled `all exercises for this course`.
8. Each answer has `Rendered` and `Raw` tabs.
9. Use `Clear data` to remove the saved archive and return to the upload screen.

Routes are bookmarkable through hash routing:

- `#/`
- `#/course/<course-id>`
- `#/course/<course-id>/all`
- `#/course/<course-id>/lecture/<lecture-id>`
- `#/course/<course-id>/lecture/<lecture-id>/section/<section-id>`
- `#/course/<course-id>/lecture/<lecture-id>/section/<section-id>/question/<exercise-slug>`

## Deployment

### Surge.sh

Build first:

```bash
pnpm build
```

Deploy:

```bash
npx surge dist your-project-name.surge.sh
```

If you want Surge to remember the domain after first deploy:

```bash
npx surge dist your-project-name.surge.sh --project ./dist
```

### Cloudflare Pages

Build first:

```bash
pnpm build
```

Deploy with Wrangler:

```bash
wrangler pages deploy dist --project-name your-project-name
```

Because the app uses hash routing, no extra redirect or SPA fallback rule is required for deep links.

## Notes

- Data is stored locally in the browser only.
- The question-rendering logic is isolated in `src/domain/renderers.js`.
- The answer renderer keeps both a polished approximation of the Meteor output and a raw-data fallback.
- Key architectural decisions are documented in [docs/ARCHITECTURE.md](/home/steve/Documents/programming/git/love-logic-server/view-extracted-exercises-static-web-application/docs/ARCHITECTURE.md).
