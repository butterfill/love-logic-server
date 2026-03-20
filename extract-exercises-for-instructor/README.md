# extract-exercises-for-instructor

Standalone Node CLI for exporting all instructor-owned courses, exercise sets, exercises, and submitted answers from the Love Logic MongoDB database.

## MongoDB Compatibility

This project intentionally uses the official MongoDB Node driver `4.1.x` rather than a newer major release. That is to preserve compatibility with older MongoDB servers used by the Meteor app, including deployments that report an older wire protocol version.

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

Optional connection override:

```bash
EXTRACTOR_MONGODB_DIRECT_CONNECTION=true|false
```

Example:

```bash
EXTRACTOR_MONGODB_URL=mongodb://localhost:27017/love-logic \
  pnpm exec extract-exercises-for-instructor extract teacher@example.com
```

### SSH Tunnel / Replica Set Note

If you connect through a local SSH port forward to a single replica-set member, the MongoDB driver can otherwise time out during topology discovery because the replica-set config advertises other hosts your machine cannot reach directly.

This tool now auto-enables `directConnection=true` for single-host loopback URLs such as `127.0.0.1` or `localhost`.

For your case, this is the right shape:

```bash
MONGODB_URL='mongodb://root:logic-vu-uk5@127.0.0.1:27018/db?authSource=admin&directConnection=true' \
  pnpm exec extract-exercises-for-instructor extract teacher@example.com
```

If needed, you can force the same behavior without editing the URI:

```bash
EXTRACTOR_MONGODB_DIRECT_CONNECTION=true \
MONGODB_URL='mongodb://root:logic-vu-uk5@127.0.0.1:27018/db?authSource=admin' \
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
