# Visual to Logical Mapping for the Possible World Logic Engine

**Project:** Love Logic Server  
**Component:** Possible World Logic Engine  
**Version:** 1.0  
**Purpose:** Defines the strict mapping rules between visual grid elements and First-Order Logic (FOL) predicates.

---

This document extracts the implicit rules buried in `ix.coffee` and `possible_world.coffee` into a formal specification. This is essential for a rewrite because these rules effectively define the "physics" of the Love Logic universe; without them, a new frontend cannot generate situations that the backend will accept as correct.

## 1. Overview

In `create`, `counter`, and `TorF` exercises, users interact with a visual grid of objects ("Possible World"). The system translates this visual state into a logical **Situation Object** to evaluate sentences like `∀x(Happy(x) → Red(x))`.

The logic engine does not "see" the grid; it sees a serialized array of objects which are then mapped to logical predicates.

## 2. Coordinate System & Object Model

The world is a 2D grid.

*   **Origin (0,0):** Top-Left corner.
*   **X-Axis:** Increases to the Right.
*   **Y-Axis:** Increases Downward.
*   **Grid Units:** Positions and sizes are integers.

### Serialized Object Structure
Every object in the visual grid generates a JSON object with these properties:

```json
{
  "x": Integer,       // Grid column (0-indexed)
  "y": Integer,       // Grid row (0-indexed)
  "w": Integer,       // Width in grid units
  "h": Integer,       // Height in grid units
  "n": String,        // Name(s) assigned (e.g., "a, b")
  "c": String,        // Color CSS name (e.g., "pink")
  "f": [String]       // Face array: [eyes, nose, mouth]
}
```

---

## 3. Unary Predicates (Features)

Unary predicates (`P(x)`) are derived from the object's intrinsic properties: Dimensions, Color, and Face Symbols.

### A. Dimensions (Size Predicates)
The system uses fixed integer thresholds to determine size predicates.

| Predicate | Condition | Logic |
| :--- | :--- | :--- |
| **Tall(x)** | Height ≥ 3 | `obj.h >= 3` |
| **Short(x)** | Height < 3 | `obj.h < 3` |
| **Wide(x)** | Width ≥ 3 | `obj.w >= 3` |
| **Narrow(x)** | Width < 3 | `obj.w < 3` |
| **Small(x)** | Area < 4 | `(obj.w * obj.h) < 4` |
| **Large(x)** | Area ≥ 4 | `(obj.w * obj.h) >= 4` |

### B. Colors
Color predicates are case-insensitive mappings of the visual color. The logic engine capitalizes the first letter of the color property.

*   **Input:** `obj.c = "pink"`
*   **Predicate:** `Pink(x)`
*   **Input:** `obj.c = "dark-grey"`
*   **Predicate:** `Dark-grey(x)` (Note: Hyphens are preserved if used in CSS class names).

### C. Face Symbols (Mood & Features)
The `f` array contains `[eyes, nose, mouth]`. Specific ASCII characters map to predicates.

#### Mouth Mappings `f[2]`
| Symbol | Predicates Implied | Meaning |
| :--- | :--- | :--- |
| `)` | `Happy(x)`, `Smiling(x)` | Standard smile |
| `(` | `Sad(x)`, `Frowning(x)` | Standard frown |
| `|` | `Neutral(x)` | Straight line mouth |
| `D` | `Laughing(x)`, `Happy(x)` | Open mouth smile |
| `()` | `Surprised(x)` | O-shaped mouth |
| `{}` | `Angry(x)` | Squiggly mouth |

#### Eye Mappings `f[0]`
| Symbol | Predicates Implied | Meaning |
| :--- | :--- | :--- |
| `:` | `Neutral(x)` | Standard dots |
| `;` | `Winking(x)` | Winking |
| `}:` | `Angry(x)` | Eyebrows |
| `:'` | `Crying(x)` | Tear drop |
| `|%` | `Confused(x)` | Mismatched eyes |

#### Nose Mappings `f[1]`
| Symbol | Predicates Implied | Meaning |
| :--- | :--- | :--- |
| `-` | `Neutral(x)` | Standard nose |
| `^` | `HasLargeNose(x)` | Carrot/triangle nose |
| `>` | (None standard) | Pointy nose |

---

## 4. Binary Predicates (Spatial & Relational)

These define the relationships between two objects `a` and `b`.

**Important:** "Left" and "Right" use strict inequality. "Above" and "Below" follow standard web coordinate logic (Top-Left origin).

### A. Positional Logic

| Predicate | Formula | Notes |
| :--- | :--- | :--- |
| **LeftOf(a, b)** | `a.x + a.w <= b.x` | `a` is strictly to the left of `b` (no overlap) |
| **RightOf(a, b)** | `a.x >= b.x + b.w` | `a` is strictly to the right of `b` |
| **Above(a, b)** | `a.y + a.h <= b.y` | `a` is strictly above `b` (visually higher, lower Y index) |
| **Below(a, b)** | `a.y >= b.y + b.h` | `a` is strictly below `b` |

### B. Adjacency Logic
Adjacency is strictly defined as touching edges with overlapping ranges. Diagonal touching does **not** count as adjacent.

**1. HorizontallyAdjacent(a, b)**
*   **Touching X:** `(a.x + a.w == b.x)` OR `(b.x + b.w == a.x)`
*   **Overlapping Y:** `(a.y < b.y + b.h)` AND `(b.y < a.y + a.h)`
*   *Both conditions must be true.*

**2. VerticallyAdjacent(a, b)**
*   **Touching Y:** `(a.y + a.h == b.y)` OR `(b.y + b.h == a.y)`
*   **Overlapping X:** `(a.x < b.x + b.w)` AND `(b.x < a.x + a.w)`
*   *Both conditions must be true.*

**3. Adjacent(a, b)**
*   `HorizontallyAdjacent(a, b)` OR `VerticallyAdjacent(a, b)`

### C. Comparative Size Logic

| Predicate | Formula |
| :--- | :--- |
| **WiderThan(a, b)** | `a.w > b.w` |
| **TallerThan(a, b)** | `a.h > b.h` |
| **LargerThan(a, b)** | `(a.w * a.h) > (b.w * b.h)` |
| **SmallerThan(a, b)** | `(a.w * a.h) < (b.w * b.h)` |
| **SameSize(a, b)** | `(a.w * a.h) == (b.w * b.h)` |
| **SameShape(a, b)** | `(a.h / a.w) == (b.h / b.w)` (Aspect ratios match) |

---

## 5. Evaluation Algorithm (The "Situation" Builder)

When grading a student submission, the system performs these steps:

1.  **Domain Creation:** Create an array of indices `[0, 1, 2...]` corresponding to the objects in the visual grid.
2.  **Name Parsing:** Iterate through objects. If `object[i].n` contains text (e.g., "a, b"), assign `names['a'] = i` and `names['b'] = i`.
3.  **Unary Extension:** Iterate through objects. For each object, derive unary predicates (Color, Size, Face) and add the object index to that predicate's extension list.
    *   *Example:* If object 0 is pink, `predicates['Pink'] = [[0]]`.
4.  **Binary Extension:** Iterate through every pair of objects `(a, b)`. Test against the spatial/relational formulas above. If true, add the tuple `[index_a, index_b]` to the predicate's extension list.
    *   *Example:* If object 0 is left of object 1, `predicates['LeftOf'] = [[0, 1]]`.
5.  **FOL Evaluation:** Pass this constructed "Situation" object to the AWFOL logic evaluator alongside the exercise sentences.

## 6. Implementation Verification Vectors

To verify a re-implementation of this logic, use these test cases:

**Case 1: Adjacency**
*   Object A: x=0, y=0, w=2, h=2
*   Object B: x=2, y=1, w=2, h=2
*   **Expected Result:** `Adjacent(a, b)` is **True**. (X edges touch at 2; Y ranges [0-2] and [1-3] overlap).

**Case 2: Corner Touching (Non-Adjacency)**
*   Object A: x=0, y=0, w=2, h=2
*   Object B: x=2, y=2, w=2, h=2
*   **Expected Result:** `Adjacent(a, b)` is **False**. (X edges touch, Y edges touch, but ranges do not strictly overlap).

**Case 3: Same Shape**
*   Object A: 2x4
*   Object B: 1x2
*   **Expected Result:** `SameShape(a, b)` is **True** (Ratio 2.0 == Ratio 2.0). `SameSize(a, b)` is **False** (Area 8 != Area 2).