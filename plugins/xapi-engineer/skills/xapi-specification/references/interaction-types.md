# xAPI Interaction Types

Detailed reference for all xAPI interaction types used in assessments.

## Overview

Interaction types define how learners respond to questions. Each type has specific format requirements for `response` and `correctResponsesPattern`.

## True/False

Binary choice questions.

**Definition:**
```json
{
  "interactionType": "true-false",
  "correctResponsesPattern": ["true"]
}
```

**Result:**
```json
{
  "response": "true",
  "success": true
}
```

**Response format:** `"true"` or `"false"` (lowercase strings)

## Choice (Multiple Choice)

Single or multiple selection from options.

**Definition:**
```json
{
  "interactionType": "choice",
  "choices": [
    { "id": "a", "description": { "en-US": "Option A" } },
    { "id": "b", "description": { "en-US": "Option B" } },
    { "id": "c", "description": { "en-US": "Option C" } },
    { "id": "d", "description": { "en-US": "Option D" } }
  ],
  "correctResponsesPattern": ["a"]
}
```

**Single selection result:**
```json
{
  "response": "a",
  "success": true
}
```

**Multiple selection (select all that apply):**
```json
{
  "interactionType": "choice",
  "correctResponsesPattern": ["a[,]c"],
  "choices": [...]
}
```

**Response format:** Choice IDs joined by `[,]` for multiple selections

## Fill-In

Short text answer questions.

**Definition:**
```json
{
  "interactionType": "fill-in",
  "correctResponsesPattern": [
    "{case_matters=false}experience api",
    "{case_matters=false}xapi"
  ]
}
```

**Result:**
```json
{
  "response": "Experience API",
  "success": true
}
```

**Response format:** Plain text string
**Pattern options:**
- `{case_matters=false}` - Case insensitive matching
- `{lang=en}` - Language specification
- Multiple patterns = alternative correct answers

## Long Fill-In

Essay or long-form text responses.

**Definition:**
```json
{
  "interactionType": "long-fill-in",
  "correctResponsesPattern": ["{lang=en}"]
}
```

**Result:**
```json
{
  "response": "The Experience API (xAPI) is a specification for learning technology that enables the collection of data about a wide range of experiences...",
  "success": null
}
```

**Note:** Long fill-in typically requires human/AI grading, so `success` may be null initially.

## Matching

Pair items from source to target.

**Definition:**
```json
{
  "interactionType": "matching",
  "source": [
    { "id": "1", "description": { "en-US": "Actor" } },
    { "id": "2", "description": { "en-US": "Verb" } },
    { "id": "3", "description": { "en-US": "Object" } }
  ],
  "target": [
    { "id": "a", "description": { "en-US": "Who performed the action" } },
    { "id": "b", "description": { "en-US": "What action was performed" } },
    { "id": "c", "description": { "en-US": "What was acted upon" } }
  ],
  "correctResponsesPattern": ["1[.]a[,]2[.]b[,]3[.]c"]
}
```

**Result:**
```json
{
  "response": "1[.]a[,]2[.]b[,]3[.]c",
  "success": true
}
```

**Response format:** `source[.]target` pairs joined by `[,]`

## Sequencing

Arrange items in correct order.

**Definition:**
```json
{
  "interactionType": "sequencing",
  "choices": [
    { "id": "launched", "description": { "en-US": "launched" } },
    { "id": "initialized", "description": { "en-US": "initialized" } },
    { "id": "completed", "description": { "en-US": "completed" } },
    { "id": "terminated", "description": { "en-US": "terminated" } }
  ],
  "correctResponsesPattern": ["launched[,]initialized[,]completed[,]terminated"]
}
```

**Result:**
```json
{
  "response": "launched[,]initialized[,]completed[,]terminated",
  "success": true
}
```

**Response format:** Choice IDs in order, joined by `[,]`

## Likert

Scale-based responses (surveys, opinions).

**Definition:**
```json
{
  "interactionType": "likert",
  "scale": [
    { "id": "1", "description": { "en-US": "Strongly Disagree" } },
    { "id": "2", "description": { "en-US": "Disagree" } },
    { "id": "3", "description": { "en-US": "Neutral" } },
    { "id": "4", "description": { "en-US": "Agree" } },
    { "id": "5", "description": { "en-US": "Strongly Agree" } }
  ]
}
```

**Result:**
```json
{
  "response": "4",
  "success": null
}
```

**Note:** Likert responses have no correct answer, so `correctResponsesPattern` is omitted and `success` is null.

## Numeric

Numerical answer questions.

**Definition:**
```json
{
  "interactionType": "numeric",
  "correctResponsesPattern": ["42[:]42"]
}
```

**Result:**
```json
{
  "response": "42",
  "success": true
}
```

**Response format:** Numeric string
**Pattern format:** `min[:]max` range or exact value `n[:]n`

**Range example:**
```json
{
  "correctResponsesPattern": ["3.14[:]3.15"]
}
```

## Performance

Multi-step procedural tasks.

**Definition:**
```json
{
  "interactionType": "performance",
  "steps": [
    { "id": "step1", "description": { "en-US": "Open the application" } },
    { "id": "step2", "description": { "en-US": "Navigate to settings" } },
    { "id": "step3", "description": { "en-US": "Enable the feature" } }
  ],
  "correctResponsesPattern": ["step1[.]correct[,]step2[.]correct[,]step3[.]correct"]
}
```

**Result:**
```json
{
  "response": "step1[.]correct[,]step2[.]correct[,]step3[.]incorrect",
  "success": false
}
```

**Response format:** `step[.]result` pairs joined by `[,]`

## Other

Free-form interaction not covered by other types.

**Definition:**
```json
{
  "interactionType": "other",
  "correctResponsesPattern": ["custom-pattern"]
}
```

Use for:
- Complex simulations
- Custom interaction mechanisms
- Proprietary question formats

## Quick Reference Table

| Type | Response Format | correctResponsesPattern |
|------|-----------------|-------------------------|
| true-false | `"true"` or `"false"` | `["true"]` |
| choice | `"id"` or `"id1[,]id2"` | `["a"]` or `["a[,]b"]` |
| fill-in | `"text"` | `["{case_matters=false}text"]` |
| long-fill-in | `"long text..."` | `["{lang=en}"]` |
| matching | `"s1[.]t1[,]s2[.]t2"` | `["1[.]a[,]2[.]b"]` |
| sequencing | `"id1[,]id2[,]id3"` | `["a[,]b[,]c"]` |
| likert | `"scale_id"` | (none - no correct answer) |
| numeric | `"42"` | `["40[:]45"]` (range) |
| performance | `"s1[.]r1[,]s2[.]r2"` | `["step1[.]correct"]` |
| other | custom | custom |
