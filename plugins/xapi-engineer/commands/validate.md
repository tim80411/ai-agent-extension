---
name: validate
description: Validate xAPI statements for structural correctness, vocabulary compliance, and cmi5 conformance
allowed-tools:
  - Read
  - AskUserQuestion
argument-hint: "[path to JSON file or paste statement]"
---

# xAPI Statement Validator

Validate xAPI statements against specification requirements through comprehensive checks.

## Workflow

### Step 1: Get Statement to Validate

If a file path is provided, read the JSON file. Otherwise, ask:

"Please provide the xAPI statement to validate. You can:
1. Paste the JSON directly
2. Provide a file path containing the statement(s)
3. Describe what you want to validate"

### Step 2: Parse and Initial Check

Attempt to parse the JSON and verify basic structure:
- Valid JSON syntax
- Root is object or array of objects
- Contains required top-level properties

### Step 3: Run Validation Checks

Execute all selected validation types:

#### Structural Validation

Check required fields and formats:

**Actor validation:**
- [ ] Has `objectType` (Agent or Group)
- [ ] Has valid identifier (mbox, mbox_sha1sum, openid, or account)
- [ ] If account: has `homePage` and `name`
- [ ] `mbox` format: `mailto:email@example.com`

**Verb validation:**
- [ ] Has `id` property (valid URI)
- [ ] Has `display` property (language map)
- [ ] Display is object with language keys

**Object validation:**
- [ ] Has `id` property
- [ ] Has `objectType` (Activity, Agent, Group, StatementRef, SubStatement)
- [ ] If Activity: `definition` is properly structured
- [ ] `definition.type` is valid URI

**Result validation (if present):**
- [ ] `score.scaled` is between -1 and 1
- [ ] `score.raw` is between `min` and `max`
- [ ] `success` is boolean
- [ ] `completion` is boolean
- [ ] `duration` is ISO 8601 duration format

**Context validation (if present):**
- [ ] `registration` is valid UUID
- [ ] `contextActivities` arrays contain valid activities
- [ ] `extensions` keys are valid URIs

#### Vocabulary Validation

Check verbs and activity types against registries:

**Verb check:**
- [ ] Verb URI matches ADL standard verbs
- [ ] Verb URI matches cmi5 defined verbs
- [ ] If custom verb: follows URI best practices

**Activity type check:**
- [ ] Activity type URI is from ADL registry
- [ ] Activity type matches the content appropriately

#### Interaction Type Validation

For `cmi.interaction` activities:

- [ ] `interactionType` is valid type
- [ ] `correctResponsesPattern` format matches type
- [ ] `choices`/`scale`/`source`/`target` arrays are valid
- [ ] Array item `id` and `description` are present

**Type-specific checks:**

| Type | Required Arrays | Pattern Format |
|------|-----------------|----------------|
| choice | choices | `"id"` or `"id1[,]id2"` |
| true-false | - | `"true"` or `"false"` |
| fill-in | - | `"{case_matters=...}text"` |
| matching | source, target | `"s[.]t[,]s[.]t"` |
| sequencing | choices | `"id1[,]id2[,]id3"` |
| likert | scale | (no pattern) |
| numeric | - | `"min[:]max"` |
| performance | steps | `"step[.]result"` |

#### cmi5 Compliance Validation

If statement claims cmi5 compliance:

- [ ] Actor uses account identifier (not mbox)
- [ ] Context includes `registration`
- [ ] Context includes `sessionId` extension
- [ ] Context includes cmi5 category
- [ ] Verb is from cmi5 defined verbs
- [ ] For passed/failed: includes `masteryScore` extension
- [ ] For passed/failed: includes `score.scaled`

### Step 4: Generate Report

Produce validation report with:

```
## Validation Report

### Summary
- Total checks: X
- Passed: Y
- Warnings: Z
- Errors: W

### Errors (Must Fix)
1. [ERROR] Actor missing required identifier
   Location: actor
   Expected: mbox, account, openid, or mbox_sha1sum

### Warnings (Should Fix)
1. [WARN] Custom verb URI detected
   Location: verb.id
   Value: https://example.com/verbs/custom
   Suggestion: Consider using ADL standard verb

### Passed Checks
- [OK] Valid JSON structure
- [OK] Actor has account identifier
- [OK] Verb has id and display
...
```

## Validation Levels

Offer validation level selection:

1. **Basic** - Structure only (required fields, types)
2. **Standard** - Structure + Vocabulary (default)
3. **Strict** - Structure + Vocabulary + cmi5 + Interaction types
4. **cmi5** - All checks with cmi5 requirements enforced

## Quick Fixes

For common errors, suggest fixes:

**Missing display:**
```json
// Before
{ "id": "http://adlnet.gov/expapi/verbs/answered" }

// After
{
  "id": "http://adlnet.gov/expapi/verbs/answered",
  "display": { "en-US": "answered" }
}
```

**Invalid score.scaled:**
```json
// Before (invalid: > 1)
{ "scaled": 1.5 }

// After
{ "scaled": 1.0 }
```

## Related Skills

Consult the xAPI Specification skill for:
- Complete field requirements
- Valid URI formats
- Interaction type details
- cmi5 profile requirements
