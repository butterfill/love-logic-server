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
5. Open a course to browse searchable exercises.
6. Open an exercise to view the rendered question and stored answers.
7. Use `Clear data` to remove the saved archive and return to the upload screen.

Routes are bookmarkable through hash routing:

- `#/`
- `#/courses/<course-id>`
- `#/courses/<course-id>/exercises/<exercise-slug>`

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
- Key architectural decisions are documented in [docs/ARCHITECTURE.md](/home/steve/Documents/programming/git/love-logic-server/view-extracted-exercises-static-web-application/docs/ARCHITECTURE.md).
