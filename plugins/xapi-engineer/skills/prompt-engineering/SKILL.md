---
name: Prompt Engineering for Assessment
description: This skill should be used when the user asks to "analyze a prompt", "design assessment prompts", "identify required materials for xAPI", "map prompt to xAPI structure", "optimize test question prompts", or needs to understand what context materials are needed to generate valid xAPI statements from educational assessment scenarios.
version: 1.0.0
---

# Prompt Engineering for Educational Assessment

Guide the analysis of prompts and identification of required materials for generating xAPI statements in educational assessment contexts.

## Core Concept: Context Material Mapping

To generate valid xAPI statements, identify and collect these material categories:

| xAPI Component | Required Materials | Source |
|----------------|-------------------|--------|
| Actor | User ID, name, account info | Authentication system |
| Verb | Action type, interaction mode | Assessment design |
| Object | Question/quiz metadata, content | Content management |
| Result | Answer, score, duration | Runtime collection |
| Context | Course hierarchy, session info | LMS context |

## Prompt Analysis Framework

### Step 1: Identify the Learning Activity Type

Determine which assessment scenario the prompt describes:

| Scenario | Characteristics | Primary Verb |
|----------|-----------------|--------------|
| Quiz attempt | Multiple questions, scored | attempted → completed |
| Single question | One interaction | answered |
| Course progress | Module completion | progressed |
| Certification | Pass/fail criteria | passed/failed |
| Practice | No scoring | experienced |

### Step 2: Extract Actor Requirements

Identify learner identification needs:

**Required materials:**
- User identifier (account ID, email, or unique name)
- Account home page (LMS URL)
- Display name (optional but recommended)

**Analysis questions:**
- How are users authenticated?
- What unique identifier is available?
- Is the actor an individual or group?

### Step 3: Map Verb Selection

Match the described action to appropriate verb:

**Decision tree:**
```
Is it a question response? → answered
Is it starting an activity? → attempted / launched
Is it finishing an activity? → completed
Is there a pass/fail criterion? → passed / failed
Is it passive consumption? → experienced
Is it progress without completion? → progressed
```

### Step 4: Define Object Structure

Extract activity/question metadata:

**For assessments:**
- Quiz/test unique identifier (URI)
- Title and description
- Activity type (assessment, cmi.interaction)
- For questions: interaction type, choices, correct answers

**For interactions:**
- Question text
- Answer options (for choice types)
- Correct response pattern
- Scoring rules

### Step 5: Determine Result Requirements

Identify what outcome data to collect:

| Result Field | When Required | Data Source |
|--------------|---------------|-------------|
| score.scaled | Scored assessments | Calculation |
| score.raw/min/max | Detailed scoring | Assessment config |
| success | Pass/fail activities | Threshold comparison |
| completion | Trackable activities | Completion logic |
| response | Question interactions | User input |
| duration | Timed activities | Timer |

### Step 6: Build Context Requirements

Identify contextual relationships:

**Hierarchical context:**
- Parent: Direct container (quiz for question)
- Grouping: Broader context (course, program)
- Category: Profile compliance (cmi5)

**Session context:**
- Registration UUID (attempt identifier)
- Platform identifier
- Language

## Material Collection Checklist

### For Quiz/Assessment Scenarios

**Before quiz starts (static materials):**
- [ ] Quiz ID and metadata (title, description)
- [ ] Question bank with IDs
- [ ] For each question:
  - [ ] Question text
  - [ ] Interaction type
  - [ ] Answer options (if applicable)
  - [ ] Correct answer(s)
  - [ ] Scoring weight
- [ ] Pass/fail threshold (if applicable)
- [ ] Time limit (if applicable)
- [ ] Course/module hierarchy

**At runtime (dynamic materials):**
- [ ] Learner account information
- [ ] Session/registration ID
- [ ] Timestamp for each action
- [ ] Learner responses
- [ ] Time spent per question
- [ ] Calculated scores

### For Single Question Scenarios

**Static materials:**
- [ ] Question ID (URI)
- [ ] Question text
- [ ] Interaction type
- [ ] Options/choices (if applicable)
- [ ] Correct response pattern
- [ ] Parent activity ID

**Dynamic materials:**
- [ ] Learner identifier
- [ ] Response value
- [ ] Response timestamp
- [ ] Duration

## Prompt-to-xAPI Mapping Examples

### Example 1: Multiple Choice Quiz

**Prompt:** "Track when a student answers a multiple choice question about xAPI verbs"

**Analysis:**
- Actor: Student (need user ID)
- Verb: answered
- Object: Question with interaction type "choice"
- Result: response, success, score

**Required materials:**
```
Static:
- Question ID: "https://lms.example.com/questions/xapi-verbs-q1"
- Question text: "Which verb indicates completion?"
- Choices: ["completed", "attempted", "launched", "terminated"]
- Correct answer: "completed"

Dynamic:
- Student account: { homePage, name }
- Response: student's selection
- Timestamp: when answered
- Duration: time to answer
```

### Example 2: Course Completion

**Prompt:** "Generate xAPI when learner finishes the xAPI fundamentals course"

**Analysis:**
- Actor: Learner
- Verb: completed
- Object: Course activity
- Result: completion=true, duration

**Required materials:**
```
Static:
- Course ID: "https://lms.example.com/courses/xapi-fundamentals"
- Course title
- Course description

Dynamic:
- Learner account
- Total duration
- Completion timestamp
```

### Example 3: Scored Assessment with Threshold

**Prompt:** "Track quiz results where 80% is passing"

**Analysis:**
- Actor: Learner
- Verb: passed or failed (based on score)
- Object: Assessment activity
- Result: score, success, completion

**Required materials:**
```
Static:
- Assessment ID
- Assessment metadata
- Mastery score: 0.8
- Maximum possible score

Dynamic:
- Learner account
- Raw score achieved
- Calculated scaled score
- Pass/fail determination
- Total duration
```

## Common Patterns

### Pattern: Question within Quiz

Context hierarchy for nested tracking:

```
Quiz (parent)
└── Question (object)
```

Statement structure:
```json
{
  "object": { "id": "question-uri" },
  "context": {
    "contextActivities": {
      "parent": [{ "id": "quiz-uri" }]
    }
  }
}
```

### Pattern: Attempt Tracking

Track individual attempts with registration:

```json
{
  "context": {
    "registration": "attempt-uuid"
  }
}
```

Use same registration for all statements in one attempt.

### Pattern: Multi-Language Content

Support internationalization:

```json
{
  "object": {
    "definition": {
      "name": {
        "en-US": "Quiz Title",
        "zh-TW": "測驗標題"
      }
    }
  }
}
```

## Validation Questions

Before generating statements, verify:

1. **Actor clarity:** Is the learner identifier unique and consistent?
2. **Verb appropriateness:** Does the verb match the actual action?
3. **Object completeness:** Are all required definition fields present?
4. **Result accuracy:** Are scores calculated correctly?
5. **Context relationships:** Are parent/grouping activities correct?
6. **Timestamp precision:** Are timestamps in ISO 8601 format?

## Additional Resources

### Reference Files

- **`references/material-templates.md`** - Templates for common scenarios
- **`references/analysis-examples.md`** - Detailed prompt analysis examples

### Related Skills

- **xAPI Specification** - Detailed xAPI structure and vocabulary
