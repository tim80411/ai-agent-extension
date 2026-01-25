# cmi5 Profile Reference

Complete guide for creating cmi5-conformant xAPI statements.

## Overview

cmi5 (Computer Managed Instruction, version 5) is a standardized xAPI profile that defines strict rules for how e-learning content communicates with an LMS via xAPI.

## Key Concepts

### Assignable Unit (AU)

The smallest unit of content that can be launched and tracked. Each AU:
- Has a unique identifier
- Can be launched independently
- Reports its own statements

### Block

A container for organizing AUs into a logical structure.

### Course

The top-level container that includes blocks and AUs.

## Required Context Extensions

All cmi5 statements must include these context extensions:

```json
{
  "context": {
    "extensions": {
      "https://w3id.org/xapi/cmi5/context/extensions/sessionid": "session-uuid"
    }
  }
}
```

### Session ID

Unique identifier for each AU launch session:
```json
"https://w3id.org/xapi/cmi5/context/extensions/sessionid": "ce909628-70d8-4edc-834a-0284739cb544"
```

### Mastery Score (for passed/failed)

Required when AU has mastery criteria:
```json
"https://w3id.org/xapi/cmi5/context/extensions/masteryscore": 0.8
```

### Launch Mode

Indicates how AU was launched:
```json
"https://w3id.org/xapi/cmi5/context/extensions/launchmode": "Normal"
```

Values: `Normal`, `Browse`, `Review`

### Launch URL

The URL used to launch the AU:
```json
"https://w3id.org/xapi/cmi5/context/extensions/launchurl": "https://content.example.com/au/123?token=xyz"
```

### Move On

Criteria for moving past this AU:
```json
"https://w3id.org/xapi/cmi5/context/extensions/moveon": "Passed"
```

Values: `Passed`, `Completed`, `CompletedAndPassed`, `CompletedOrPassed`, `NotApplicable`

## cmi5 Defined Verbs

### Verb Sequence

```
LMS                          AU (Content)
 |                              |
 |-------- launched ----------->|
 |                              |
 |<------- initialized ---------|
 |                              |
 |        [learning occurs]     |
 |                              |
 |<------- completed -----------|
 |<------- passed/failed -------|
 |                              |
 |<------- terminated ----------|
```

### launched

Sent by LMS when AU is started.

```json
{
  "actor": { "account": { "homePage": "https://lms.example.com", "name": "user123" } },
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/launched",
    "display": { "en-US": "launched" }
  },
  "object": {
    "id": "https://example.com/au/intro-to-xapi",
    "definition": {
      "name": { "en-US": "Introduction to xAPI" },
      "type": "https://w3id.org/xapi/cmi5/activitytype/block"
    }
  },
  "context": {
    "registration": "registration-uuid",
    "extensions": {
      "https://w3id.org/xapi/cmi5/context/extensions/sessionid": "session-uuid",
      "https://w3id.org/xapi/cmi5/context/extensions/launchmode": "Normal",
      "https://w3id.org/xapi/cmi5/context/extensions/launchurl": "https://content.example.com/au/123"
    },
    "contextActivities": {
      "category": [{ "id": "https://w3id.org/xapi/cmi5/context/categories/cmi5" }]
    }
  }
}
```

### initialized

Sent by AU when ready for learner interaction.

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/initialized",
    "display": { "en-US": "initialized" }
  }
}
```

### completed

Sent when learner completes the content (regardless of success).

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/completed",
    "display": { "en-US": "completed" }
  },
  "result": {
    "completion": true,
    "duration": "PT15M30S"
  }
}
```

### passed

Sent when learner meets mastery criteria.

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/passed",
    "display": { "en-US": "passed" }
  },
  "result": {
    "success": true,
    "score": {
      "scaled": 0.92
    },
    "duration": "PT10M"
  },
  "context": {
    "extensions": {
      "https://w3id.org/xapi/cmi5/context/extensions/masteryscore": 0.8
    }
  }
}
```

### failed

Sent when learner does not meet mastery criteria.

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/failed",
    "display": { "en-US": "failed" }
  },
  "result": {
    "success": false,
    "score": {
      "scaled": 0.65
    }
  }
}
```

### terminated

Sent when AU session ends normally.

```json
{
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/terminated",
    "display": { "en-US": "terminated" }
  },
  "result": {
    "duration": "PT20M"
  }
}
```

### abandoned

Sent by LMS when session times out without proper termination.

```json
{
  "verb": {
    "id": "https://w3id.org/xapi/adl/verbs/abandoned",
    "display": { "en-US": "abandoned" }
  }
}
```

### satisfied

Sent when an objective or block is satisfied.

```json
{
  "verb": {
    "id": "https://w3id.org/xapi/adl/verbs/satisfied",
    "display": { "en-US": "satisfied" }
  },
  "object": {
    "id": "https://example.com/objectives/understand-xapi",
    "definition": {
      "type": "http://adlnet.gov/expapi/activities/objective"
    }
  }
}
```

## Complete cmi5 Statement Example

Full example of a passed statement with all required elements:

```json
{
  "id": "12345678-1234-1234-1234-123456789012",
  "actor": {
    "objectType": "Agent",
    "account": {
      "homePage": "https://lms.example.com",
      "name": "learner-001"
    }
  },
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/passed",
    "display": { "en-US": "passed" }
  },
  "object": {
    "objectType": "Activity",
    "id": "https://example.com/au/xapi-fundamentals",
    "definition": {
      "name": { "en-US": "xAPI Fundamentals Quiz" },
      "description": { "en-US": "Assessment of xAPI basic concepts" },
      "type": "http://adlnet.gov/expapi/activities/assessment"
    }
  },
  "result": {
    "success": true,
    "completion": true,
    "score": {
      "scaled": 0.88,
      "raw": 88,
      "min": 0,
      "max": 100
    },
    "duration": "PT12M45S"
  },
  "context": {
    "registration": "reg-uuid-12345",
    "contextActivities": {
      "parent": [{
        "id": "https://example.com/courses/learning-analytics-101",
        "objectType": "Activity"
      }],
      "category": [{
        "id": "https://w3id.org/xapi/cmi5/context/categories/cmi5",
        "objectType": "Activity"
      }]
    },
    "extensions": {
      "https://w3id.org/xapi/cmi5/context/extensions/sessionid": "session-abc123",
      "https://w3id.org/xapi/cmi5/context/extensions/masteryscore": 0.8,
      "https://w3id.org/xapi/cmi5/context/extensions/launchmode": "Normal"
    }
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Validation Checklist

### Required for All cmi5 Statements

- [ ] Actor uses account identifier (not mbox)
- [ ] Context includes registration UUID
- [ ] Context includes sessionId extension
- [ ] Context includes cmi5 category

### Verb-Specific Requirements

**launched:**
- [ ] Sent by LMS only
- [ ] Includes launchmode extension
- [ ] Includes launchurl extension

**passed/failed:**
- [ ] Includes score.scaled in result
- [ ] Includes masteryscore in context extensions
- [ ] success boolean matches verb

**terminated:**
- [ ] Includes duration in result
- [ ] Is the last statement in session (except abandoned)

### Statement Ordering

- [ ] launched is first
- [ ] initialized follows launched
- [ ] completed before passed/failed (for mastered content)
- [ ] terminated is last (or abandoned if timeout)
