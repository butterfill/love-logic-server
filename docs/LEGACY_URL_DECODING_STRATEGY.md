# Legacy URL Decoding & Canonicalization Strategy

**Status:** CRITICAL
**Component:** Routing / Database Key Generation
**Target System:** Any replacement frontend (React/Next.js/Vue)

## 1. The Business Problem

Love Logic Server relies entirely on **URL-based exercise definitions**. The state of an exercise (premises, conclusion, world configuration) is stored in the URL path, not in a database document.

Additionally, the database keys (`exerciseId`) for student submissions and graded answer caches are **derived directly from the URL**.

**The Risk:** Modern web frameworks (Next.js, Express, React Router) handle URL decoding differently than the legacy Meteor/FlowRouter stack. If the new system decodes a URL slightly differently (e.g., handling `+` vs `%20`, or `%7C` vs `|`), it will generate a different `exerciseId`.

**Consequence:** The system will fail to find:
1. The student's previous submissions.
2. Cached human grading results (breaking auto-grading).
3. Unanswered help requests associated with that exercise.

---

## 2. The Canonical ID Algorithm

The legacy system forces all incoming URLs into a "Canonical ID" format before querying the database. The new system **must** replicate this exact string manipulation logic to match existing database records.

### The Algorithm (`ix.convertToExerciseId`)

Located in `client/lib/ix.coffee`:

```javascript
function convertToLegacyExerciseId(rawUrlPath) {
  // 1. Remove trailing slash
  let cleanPath = rawUrlPath.replace(/\/$/, '');

  // 2. Split by forward slash '/'
  // Note: This relies on the browser having NOT pre-decoded encoded slashes (%2F)
  let segments = cleanPath.split('/');

  // 3. Map over segments: Decode, then Re-Encode
  // This handles cases of double-encoding or mixed encoding states
  let canonicalSegments = segments.map(segment => {
    // Decode first to get to raw state (handles %20, +, %7C, etc.)
    const decoded = decodeURIComponent(segment);
    
    // Re-encode using strict encodeURIComponent
    // This standardizes space to %20 (not +) and encodes special chars
    return encodeURIComponent(decoded);
  });

  // 4. Rejoin with slashes
  return canonicalSegments.join('/');
}
```

### Example Transformation

| User Input / Browser Bar | Legacy Canonical ID (Database Key) |
|--------------------------|-----------------------------------|
| `/ex/proof/from/A and B/to/A` | `/ex/proof/from/A%20and%20B/to/A` |
| `/ex/tt/qq/A|B` | `/ex/tt/qq/A%7CB` |
| `/ex/q/What%20is%20x?` | `/ex/q/What%20is%20x%3F` |

---

## 3. Parsing Logic & Parameter Extraction

Once the Canonical ID is generated for database lookups, the application must parse the URL to render the exercise. The legacy app uses a positional strategy combined with specific delimiters.

### 3.1 General Route Pattern

```
/ex/{TYPE}/{SUBTYPE?}/{KEY_1}/{VAL_1}/{KEY_2}/{VAL_2}...
```

1.  **TYPE** (Index 2): `proof`, `tt`, `create`, `trans`, etc.
2.  **SUBTYPE** (Index 3, Optional): 
    *   Detected via list: `orValid`, `orInvalid`, `noQ`, `require`.
    *   If the segment at Index 3 matches a keyword, it is a subtype.
    *   If not, Index 3 is the start of a Key/Value pair.

### 3.2 The Pipe Separator (`|`)

The application uses the pipe character (`|`, encoded as `%7C`) as a list separator within a single URL segment.

**Critical Behavior:**
When parsing a parameter (e.g., `qq`, `from`, `names`), the system must:
1.  **Decode** the specific segment.
2.  **Split** by the pipe character `|`.
3.  **Process** each resulting item individually.

**Example (`client/lib/ix.coffee` logic):**
```javascript
// URL Segment: "A%20and%20B%7CB%20and%20C"
const rawParam = "A%20and%20B%7CB%20and%20C";
const decoded = decodeURIComponent(rawParam); // "A and B|B and C"
const items = decoded.split('|'); // ["A and B", "B and C"]
```

### 3.3 Specific Parameter Parsers

The new system must implement parsers for these specific keys found in `ix.coffee`:

#### `TTrow` (Truth Table Row)
*   **Format:** `Var:Bool|Var:Bool`
*   **Legacy Parsing Logic:**
    1. Decode and Split by `|`.
    2. Split each item by `:`.
    3. Map: `{ "A": "T", "B": "F" }`

#### `world` (JSON World Definition)
*   **Format:** URI-encoded JSON string.
*   **Legacy Parsing Logic:**
    1. `decodeURIComponent(segment)`
    2. `JSON.parse(string)`
    *   *Note:* The JSON uses abbreviated keys (`w`, `h`, `n`, `c`, `f`) to save space. See `UI_COMPONENTS_FLOWS.md` for the mapping.

#### `names` (Translation Exercises)
*   **Format:** `a=Name|b=Name`
*   **Legacy Parsing Logic:**
    1. Decode and Split by `|`.
    2. Replace `=` with ` : `.
    3. Result: `["a : Ayesha", "b : Beatrice"]`

---

## 4. Logic Symbol Encoding

The legacy app accepts logic symbols in URL parameters. The new router must handle Unicode characters correctly during the Decode/Encode cycle.

| Symbol | URL Encoded | Meaning |
|--------|-------------|---------|
| `∧`    | `%E2%88%A7` | AND |
| `∨`    | `%E2%88%A8` | OR |
| `¬`    | `%C2%AC`    | NOT |
| `→`    | `%E2%86%92` | IMPLIES |
| `∀`    | `%E2%88%80` | FORALL |
| `∃`    | `%E2%88%83` | EXISTS |

**Requirement:** Ensure the server configuration (e.g., Nginx, Vercel) allows these characters in the URL path and query string.

---

## 5. Test Vectors for Implementation

Use these vectors to write unit tests for your new URL parser and ID generator.

### Vector 1: Standard Proof
**Input URL:**
`/ex/proof/from/A and B/to/A`

**Expected Canonical ID (Database Key):**
`/ex/proof/from/A%20and%20B/to/A`

**Parsed Parameters:**
*   Type: `proof`
*   Premises: `["A and B"]`
*   Conclusion: `A`

### Vector 2: Truth Table with Pipes & Symbols
**Input URL:**
`/ex/tt/qq/A ∨ B|¬A`

**Expected Canonical ID:**
`/ex/tt/qq/A%20%E2%88%A8%20B%7C%C2%ACA`

**Parsed Parameters:**
*   Type: `tt`
*   Sentences: `["A ∨ B", "¬A"]`

### Vector 3: Complex World Creation (JSON)
**Input URL:**
`/ex/create/qq/Happy(a)/world/[{"x":0,"y":0,"n":"a","c":"red"}]`

**Expected Canonical ID:**
`/ex/create/qq/Happy(a)/world/%5B%7B%22x%22%3A0%2C%22y%22%3A0%2C%22n%22%3A%22a%22%2C%22c%22%3A%22red%22%7D%5D`

**Parsed Parameters:**
*   Type: `create`
*   Sentences: `["Happy(a)"]`
*   World Object: `[{x:0, y:0, n:"a", c:"red"}]`

---

## 6. Implementation Checklist

1.  [ ] **Middleware/Utility:** Create a utility function `normalizeExerciseId(url)` that replicates the Algorithm in Section 2 exactly.
2.  [ ] **Database Migration (Optional):** If migrating data, do NOT attempt to "clean" or decoding existing `exerciseId` fields in MongoDB. They must remain URL-encoded strings to match the client generation logic.
3.  [ ] **Router Config:** Configure the new router (e.g., Next.js `next.config.js`) to allow double-slashes or special characters if they appear in legacy links (though typically the app doesn't use double slashes).
4.  [ ] **Unit Tests:** Verify that `normalizeExerciseId` outputs match the Test Vectors in Section 5.

