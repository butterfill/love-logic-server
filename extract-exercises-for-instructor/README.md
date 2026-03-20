# extract-exercises-for-instructor

Standalone Node CLI for exporting all instructor-owned courses, exercise sets, exercises, and submitted answers from the Love Logic MongoDB database.

## Install

From this directory:

```bash
pnpm install
```

## Test

```bash
pnpm test
```

## Usage

The CLI command is:

```bash
node src/cli.js extract <email-address>
```

You can also run it through `pnpm`:

```bash
pnpm exec extract-exercises-for-instructor extract <email-address>
```

By default the tool connects to:

```bash
mongodb://localhost:27017/love-logic
```

You can override this with any of these environment variables:

```bash
EXTRACTOR_MONGODB_URL=...
MONGODB_URL=...
MONGO_URL=...
```

Example:

```bash
EXTRACTOR_MONGODB_URL=mongodb://localhost:27017/love-logic \
  pnpm exec extract-exercises-for-instructor extract teacher@example.com
```

This writes:

```text
./teacher@example.com.json
```

If the output file already exists, the CLI asks before overwriting it. To skip the prompt:

```bash
pnpm exec extract-exercises-for-instructor extract --force teacher@example.com
```

## Output Shape

The JSON output includes:

- `instructor`: the matched Mongo user with primary email and profile data
- `exerciseIds`: the distinct exercise ids found in the instructor's owned exercise sets
- `courses`: instructor-owned course content grouped as `course -> exerciseSets -> lectures -> units -> exercises`
- `answers`: stored under each exercise entry as the matching `submitted_exercises` documents for that exercise id

Only exercise sets with `owner === instructor._id` are exported, and only submissions whose `exerciseId` appears in those owned exercise sets are included.
