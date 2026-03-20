# Architecture

## Main decisions

### 1. Normalize imported JSON before any UI renders

The uploaded document is converted into a route-friendly index in `src/domain/normalize.js`.

Why:

- Vue components stay simple and mostly presentational.
- Bookmarkable routes can look up exercises in O(1) through `exercisesBySlug`.
- Domain logic can be tested independently of the browser UI.

### 2. Keep exercise rendering logic out of Vue components

Exercise-question parsing and answer summarization live in `src/domain/renderers.js`.

Why:

- The exercise ids are legacy URL formats from Meteor and deserve their own isolated parsing layer.
- Question-type rendering can be extended without touching route or view components.
- Vitest can lock in behavior for each exercise type without component brittleness.

The answer cards always expose two views:

- `Rendered`: the best approximation of the original Meteor presentation
- `Raw`: the underlying stored answer document

That keeps the new renderer safe to evolve while preserving direct access to the source data.

### 3. Use IndexedDB for browser-local persistence

The uploaded archive is stored in IndexedDB through `src/domain/storage.js`. On startup, the app also checks for the old `localStorage` archive key, deletes it if present, and exposes a notice that the user must re-upload.

Why:

- The app is static and has no backend.
- The archive is instructor-private and remains on the instructor's device.
- IndexedDB can handle large instructor archives that exceed `localStorage` quotas.
- The clear-data flow still has a single responsibility and can fully reset the app to the upload state.

### 4. Hash-based routing for static hosting

The router uses `createWebHashHistory()`.

Why:

- Bookmarkable views still work.
- Surge and Cloudflare Pages need no extra rewrite rules for deep links.
- Static deployment stays simple and robust.

### 5. Awfol is used in the domain layer, not directly in the templates

`@butterfill/awfol/browser` is used to parse and stringify logic formulas for display.

Why:

- It matches the source system’s parsing and symbol replacement more closely than ad hoc formatting.
- The rendering layer remains reusable in non-Vue contexts.
- Future migration to richer renderers can happen behind one interface.
