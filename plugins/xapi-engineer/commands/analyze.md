---
name: analyze
description: Analyze prompts or scenarios to identify required materials and context for generating xAPI statements
allowed-tools:
  - Read
  - AskUserQuestion
  - Grep
argument-hint: "[prompt or scenario to analyze]"
---

# Prompt Analyzer for xAPI

Analyze prompts and scenarios to identify all required materials for generating valid xAPI statements.

## Workflow

### Step 1: Receive Input

If prompt/scenario is provided in arguments, analyze it. Otherwise, ask:

"Please describe the educational assessment scenario you want to track with xAPI. For example:
- 'Track when students answer quiz questions'
- 'Record course completion with scores'
- 'Log practice session interactions'"

### Step 2: Identify Scenario Type

Classify the scenario:

| Category | Indicators | Primary Statements |
|----------|------------|-------------------|
| Quiz/Assessment | "quiz", "test", "exam", "score" | attempted, answered, completed, passed/failed |
| Single Interaction | "question", "answer", "respond" | answered |
| Course Progress | "complete", "finish", "module" | completed, progressed |
| Content Consumption | "watch", "read", "view" | experienced |
| Practice/Drill | "practice", "drill", "exercise" | attempted, experienced |
| Certification | "certify", "pass", "qualify" | passed, failed |

### Step 3: Map to xAPI Components

For each identified component, list required materials:

```
## xAPI Component Analysis

### Actor (Who)
Required materials:
- [ ] User identifier source: ___
- [ ] Account home page URL: ___
- [ ] Display name field: ___

### Verb (Action)
Recommended verb: ___
URI: ___
Alternatives: ___

### Object (What)
Activity type: ___
Required materials:
- [ ] Activity ID pattern: ___
- [ ] Activity name: ___
- [ ] Activity description: ___
- [ ] Interaction type (if applicable): ___
- [ ] Choices/options (if applicable): ___
- [ ] Correct answer(s) (if applicable): ___

### Result (Outcome)
Required materials:
- [ ] Score calculation method: ___
- [ ] Pass/fail threshold: ___
- [ ] Completion criteria: ___
- [ ] Duration tracking: ___
- [ ] Response capture: ___

### Context (Where/When)
Required materials:
- [ ] Parent activity: ___
- [ ] Grouping activities: ___
- [ ] Registration/session tracking: ___
- [ ] Platform identifier: ___
```

### Step 4: Identify Data Sources

Map materials to data sources:

```
## Data Source Mapping

### Static Data (Pre-configured)
| Material | Source | Example |
|----------|--------|---------|
| Activity ID | Configuration | "https://lms.com/quizzes/123" |
| Question text | Content DB | "What is xAPI?" |
| Correct answers | Content DB | ["Experience API"] |

### Dynamic Data (Runtime)
| Material | Source | Capture Method |
|----------|--------|----------------|
| User ID | Auth system | Session token |
| Response | User input | Form submission |
| Duration | Timer | Start/end timestamps |
| Score | Calculation | Sum of correct answers |
```

### Step 5: Generate Material Checklist

Produce actionable checklist:

```
## Material Collection Checklist

### Before Implementation
- [ ] Define activity ID URI pattern
- [ ] Prepare activity metadata (names, descriptions)
- [ ] Configure interaction types and correct answers
- [ ] Set up score calculation logic
- [ ] Define pass/fail thresholds
- [ ] Establish parent/grouping relationships

### At Runtime
- [ ] Capture authenticated user account
- [ ] Generate registration UUID per attempt
- [ ] Record timestamp for each action
- [ ] Collect user responses
- [ ] Calculate duration
- [ ] Compute scores
```

### Step 6: Provide Code Integration Hints

If analyzing code or reading project files:

```typescript
// Suggested data structure for xAPI materials
interface XAPIStatementMaterials {
  actor: {
    homePage: string;  // From: config.lmsUrl
    userId: string;    // From: auth.currentUser.id
    name?: string;     // From: auth.currentUser.displayName
  };

  activity: {
    id: string;        // From: quiz.id or question.id
    name: string;      // From: quiz.title
    type: string;      // Constant: assessment or cmi.interaction
  };

  result: {
    response: string;  // From: userAnswer
    score: number;     // From: calculateScore()
    success: boolean;  // From: score >= passingThreshold
    duration: string;  // From: formatDuration(endTime - startTime)
  };

  context: {
    registration: string;  // From: generateUUID() per attempt
    parentId?: string;     // From: quiz.id (for question statements)
  };
}
```

## Output Format

### Analysis Summary

```
## Prompt Analysis Summary

**Scenario:** [Brief description]
**Statement Types:** [List of verbs to generate]
**Complexity:** [Simple | Moderate | Complex]

### Key Findings
1. [Finding 1]
2. [Finding 2]

### Required Materials (X items)
- Static: Y items
- Dynamic: Z items

### Recommended Next Steps
1. [Step 1]
2. [Step 2]
```

### Detailed Material Specification

Provide complete material specifications in YAML or JSON format for easy integration.

## Analysis Depth Levels

Offer analysis depth selection:

1. **Quick** - Basic component identification
2. **Standard** - Full material mapping (default)
3. **Deep** - Include code integration suggestions
4. **Project** - Analyze project files for existing patterns

## Related Skills

- **xAPI Specification** - For verb/activity type selection
- **Prompt Engineering for Assessment** - For detailed mapping patterns
