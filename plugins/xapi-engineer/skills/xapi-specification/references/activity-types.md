# xAPI Activity Types

Complete reference for activity type URIs used in educational contexts.

## ADL Standard Activity Types

### Learning Content

| Activity Type | URI | Description |
|---------------|-----|-------------|
| Course | `http://adlnet.gov/expapi/activities/course` | Complete course or curriculum |
| Module | `http://adlnet.gov/expapi/activities/module` | Section of a course |
| Lesson | `http://adlnet.gov/expapi/activities/lesson` | Individual lesson unit |
| Assessment | `http://adlnet.gov/expapi/activities/assessment` | Quiz, test, or exam |
| Question | `http://adlnet.gov/expapi/activities/question` | Individual question |
| Interaction | `http://adlnet.gov/expapi/activities/cmi.interaction` | Interactive question with response tracking |

### Media Types

| Activity Type | URI | Description |
|---------------|-----|-------------|
| Media | `http://adlnet.gov/expapi/activities/media` | Generic media content |
| Video | `https://w3id.org/xapi/video/activity-type/video` | Video content |
| Audio | `https://w3id.org/xapi/audio/activity-type/audio` | Audio content |
| File | `http://adlnet.gov/expapi/activities/file` | Downloadable file |
| Link | `http://adlnet.gov/expapi/activities/link` | External URL |

### Social & Collaborative

| Activity Type | URI | Description |
|---------------|-----|-------------|
| Meeting | `http://adlnet.gov/expapi/activities/meeting` | Synchronous session |
| Discussion | `https://w3id.org/xapi/acrossx/activities/discussion` | Forum or thread |
| Message | `https://w3id.org/xapi/acrossx/activities/message` | Individual message |
| Collaboration | `https://w3id.org/xapi/acrossx/activities/collaboration` | Group work |

### Performance & Simulation

| Activity Type | URI | Description |
|---------------|-----|-------------|
| Simulation | `http://adlnet.gov/expapi/activities/simulation` | Simulated environment |
| Performance | `http://adlnet.gov/expapi/activities/performance` | Performance task |
| Objective | `http://adlnet.gov/expapi/activities/objective` | Learning objective |
| Attempt | `http://adlnet.gov/expapi/activities/attempt` | Single attempt at activity |

## cmi5 Activity Types

| Activity Type | URI | Usage |
|---------------|-----|-------|
| Block | `https://w3id.org/xapi/cmi5/activitytype/block` | Container for AUs |
| Course | `https://w3id.org/xapi/cmi5/activitytype/course` | cmi5 course structure |

## Assessment-Specific Types

### Quiz Structure

```
Course (course)
└── Module (module)
    └── Assessment (assessment)
        └── Question (cmi.interaction)
```

### Example: Complete Quiz Definition

**Quiz container:**
```json
{
  "objectType": "Activity",
  "id": "https://example.com/quizzes/xapi-basics",
  "definition": {
    "name": { "en-US": "xAPI Basics Quiz" },
    "description": { "en-US": "Test your knowledge of xAPI fundamentals" },
    "type": "http://adlnet.gov/expapi/activities/assessment"
  }
}
```

**Question within quiz:**
```json
{
  "objectType": "Activity",
  "id": "https://example.com/quizzes/xapi-basics/q1",
  "definition": {
    "name": { "en-US": "Question 1" },
    "description": { "en-US": "What does xAPI stand for?" },
    "type": "http://adlnet.gov/expapi/activities/cmi.interaction",
    "interactionType": "choice",
    "choices": [
      { "id": "a", "description": { "en-US": "Experience API" } },
      { "id": "b", "description": { "en-US": "Extended API" } }
    ],
    "correctResponsesPattern": ["a"]
  }
}
```

## Context Activity Relationships

### Parent

Direct container relationship:
```json
{
  "contextActivities": {
    "parent": [{
      "id": "https://example.com/quizzes/xapi-basics",
      "objectType": "Activity",
      "definition": {
        "type": "http://adlnet.gov/expapi/activities/assessment"
      }
    }]
  }
}
```

### Grouping

Broader organizational context:
```json
{
  "contextActivities": {
    "grouping": [{
      "id": "https://example.com/courses/learning-analytics",
      "objectType": "Activity",
      "definition": {
        "type": "http://adlnet.gov/expapi/activities/course"
      }
    }]
  }
}
```

### Category

Profile or standard compliance:
```json
{
  "contextActivities": {
    "category": [{
      "id": "https://w3id.org/xapi/cmi5/context/categories/cmi5",
      "objectType": "Activity"
    }]
  }
}
```

## Custom Activity Types

Create custom types when standard types don't fit:

**URI Structure:**
```
https://{your-domain}/xapi/activities/{type-name}
```

**Example:**
```json
{
  "type": "https://example.com/xapi/activities/flashcard-deck"
}
```

### Best Practices

1. **Use standard types first** - Check ADL registry before creating custom
2. **Follow URI conventions** - Use your domain, consistent path structure
3. **Document thoroughly** - Maintain internal registry with descriptions
4. **Be specific** - Create meaningful types, not generic ones

## Activity ID Best Practices

### URI Structure

```
https://{domain}/{type}/{identifier}
```

Examples:
- `https://lms.example.com/courses/CS101`
- `https://lms.example.com/quizzes/midterm-2024`
- `https://lms.example.com/questions/q-12345`

### Guidelines

1. **Use stable URIs** - IDs should not change over time
2. **Include meaningful segments** - Make IDs human-readable
3. **Avoid query parameters** - Use path segments instead
4. **Use HTTPS** - Prefer secure URIs
5. **Consider versioning** - Include version if content changes significantly

### Anti-patterns

❌ `https://example.com/activity?id=123&type=quiz` (query params)
❌ `urn:uuid:12345` (opaque identifier)
❌ `http://example.com/quiz` (too generic)

✅ `https://example.com/quizzes/intro-to-xapi-v1`
✅ `https://example.com/courses/2024/fall/cs101/quiz-1`
