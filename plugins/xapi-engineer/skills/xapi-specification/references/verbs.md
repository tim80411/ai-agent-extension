# xAPI Verbs Registry

Complete reference for ADL and cmi5 verbs used in educational assessment.

## ADL Standard Verbs

### Core Learning Verbs

| Verb | URI | Description |
|------|-----|-------------|
| answered | `http://adlnet.gov/expapi/verbs/answered` | Responded to a question |
| asked | `http://adlnet.gov/expapi/verbs/asked` | Posed a question |
| attempted | `http://adlnet.gov/expapi/verbs/attempted` | Started an activity |
| attended | `http://adlnet.gov/expapi/verbs/attended` | Was present at an event |
| commented | `http://adlnet.gov/expapi/verbs/commented` | Provided feedback |
| completed | `http://adlnet.gov/expapi/verbs/completed` | Finished an activity |
| exited | `http://adlnet.gov/expapi/verbs/exited` | Left an activity |
| experienced | `http://adlnet.gov/expapi/verbs/experienced` | Witnessed or underwent |
| failed | `http://adlnet.gov/expapi/verbs/failed` | Did not pass |
| imported | `http://adlnet.gov/expapi/verbs/imported` | Brought in content |
| initialized | `http://adlnet.gov/expapi/verbs/initialized` | Started a session |
| interacted | `http://adlnet.gov/expapi/verbs/interacted` | Engaged with content |
| launched | `http://adlnet.gov/expapi/verbs/launched` | Started an application |
| mastered | `http://adlnet.gov/expapi/verbs/mastered` | Achieved mastery |
| passed | `http://adlnet.gov/expapi/verbs/passed` | Successfully completed |
| preferred | `http://adlnet.gov/expapi/verbs/preferred` | Indicated preference |
| progressed | `http://adlnet.gov/expapi/verbs/progressed` | Made progress |
| registered | `http://adlnet.gov/expapi/verbs/registered` | Enrolled or signed up |
| responded | `http://adlnet.gov/expapi/verbs/responded` | Replied to something |
| resumed | `http://adlnet.gov/expapi/verbs/resumed` | Continued after pause |
| scored | `http://adlnet.gov/expapi/verbs/scored` | Achieved a score |
| shared | `http://adlnet.gov/expapi/verbs/shared` | Distributed content |
| suspended | `http://adlnet.gov/expapi/verbs/suspended` | Paused an activity |
| terminated | `http://adlnet.gov/expapi/verbs/terminated` | Ended a session |
| voided | `http://adlnet.gov/expapi/verbs/voided` | Invalidated a statement |

## cmi5 Defined Verbs

Required verbs for cmi5-conformant content:

| Verb | URI | When to Use |
|------|-----|-------------|
| launched | `http://adlnet.gov/expapi/verbs/launched` | LMS launches AU |
| initialized | `http://adlnet.gov/expapi/verbs/initialized` | AU ready for learner |
| completed | `http://adlnet.gov/expapi/verbs/completed` | Learner finished content |
| passed | `http://adlnet.gov/expapi/verbs/passed` | Met mastery criteria |
| failed | `http://adlnet.gov/expapi/verbs/failed` | Did not meet criteria |
| abandoned | `https://w3id.org/xapi/adl/verbs/abandoned` | Session timed out |
| waived | `https://w3id.org/xapi/adl/verbs/waived` | Requirement bypassed |
| terminated | `http://adlnet.gov/expapi/verbs/terminated` | AU session ended |
| satisfied | `https://w3id.org/xapi/adl/verbs/satisfied` | Objective achieved |

### cmi5 Verb Sequence Rules

```
launched → initialized → [completed|passed|failed] → terminated
                      ↘ abandoned (timeout)
```

- `launched` must be first
- `initialized` must follow `launched`
- `terminated` must be last (unless `abandoned`)
- `passed`/`failed` require `completed` for mastered content

## Assessment-Specific Verbs

### Question Interaction Verbs

| Verb | URI | Use Case |
|------|-----|----------|
| answered | `http://adlnet.gov/expapi/verbs/answered` | Submitted answer to question |
| skipped | `https://w3id.org/xapi/adl/verbs/skipped` | Bypassed a question |
| reviewed | `https://w3id.org/xapi/acrossx/verbs/reviewed` | Looked back at answer |

### Quiz/Test Verbs

| Verb | URI | Use Case |
|------|-----|----------|
| attempted | `http://adlnet.gov/expapi/verbs/attempted` | Started quiz |
| completed | `http://adlnet.gov/expapi/verbs/completed` | Finished quiz |
| passed | `http://adlnet.gov/expapi/verbs/passed` | Passed quiz |
| failed | `http://adlnet.gov/expapi/verbs/failed` | Failed quiz |
| scored | `http://adlnet.gov/expapi/verbs/scored` | Received score |

## Custom Verb Guidelines

When standard verbs don't fit, create custom verbs:

### URI Structure

```
https://{your-domain}/xapi/verbs/{verb-name}
```

Example:
```json
{
  "id": "https://example.com/xapi/verbs/practiced",
  "display": {
    "en-US": "practiced",
    "zh-TW": "練習了"
  }
}
```

### Best Practices

1. **Check existing registries first** - Reuse standard verbs when possible
2. **Use past tense** - "answered" not "answer"
3. **Be specific** - "submitted-essay" vs generic "submitted"
4. **Include display in multiple languages** if supporting i18n
5. **Document your verbs** - Maintain internal verb registry

## Verb Usage Examples

### Answering a Question

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/answered",
    "display": { "en-US": "answered" }
  }
}
```

### Completing an Assessment

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/completed",
    "display": { "en-US": "completed" }
  }
}
```

### Passing with Score

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/passed",
    "display": { "en-US": "passed" }
  },
  "result": {
    "score": { "scaled": 0.85 },
    "success": true
  }
}
```

### Quiz Attempt Sequence

1. `attempted` - Start quiz
2. `answered` - Each question (multiple statements)
3. `completed` - Finish quiz
4. `passed` or `failed` - Final result
