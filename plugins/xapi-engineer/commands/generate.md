---
name: generate
description: Generate xAPI statements from assessment scenario descriptions through interactive dialogue
allowed-tools:
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[scenario description]"
---

# xAPI Statement Generator

Generate valid xAPI statements for educational assessment scenarios through interactive material collection.

## Workflow

### Step 1: Understand the Scenario

If scenario description is provided in arguments, analyze it. Otherwise, ask:

"What assessment scenario do you want to generate xAPI statements for?"

Options to offer:
- Quiz/test completion
- Single question response
- Course/module completion
- Learning progress tracking
- Custom scenario

### Step 2: Collect Actor Information

Ask for learner identification:

"How are learners identified in your system?"

Collect:
- Account home page (LMS URL)
- User identifier format
- Display name availability

### Step 3: Determine Activity Type

Based on scenario, identify:
- Activity type (assessment, cmi.interaction, course, etc.)
- Activity ID pattern (URI structure)
- Activity metadata (name, description)

For quiz/question scenarios, ask:
- "What interaction type? (multiple choice, true/false, fill-in, etc.)"
- "How many questions?"
- "Is there a passing score threshold?"

### Step 4: Define Result Structure

Ask about outcome tracking:
- "Do you need to track scores?" (scaled, raw, min, max)
- "Is there pass/fail criteria?"
- "Should completion be tracked?"
- "Is duration tracking required?"

### Step 5: Establish Context

Ask about hierarchical relationships:
- "What is the parent activity?" (quiz for question, course for module)
- "Any grouping context?" (program, organization)
- "Is this cmi5-conformant?"

### Step 6: Generate Statements

Based on collected information, generate:

1. **Statement template** with placeholders for dynamic values
2. **Complete example** with sample data
3. **TypeScript/JavaScript interface** for the data structure (optional)

## Output Format

Provide statements in JSON format with clear annotations:

```json
{
  // Actor: The learner performing the action
  "actor": {
    "objectType": "Agent",
    "account": {
      "homePage": "https://your-lms.example.com",
      "name": "{{userId}}"
    }
  },
  // Verb: The action performed
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/answered",
    "display": { "en-US": "answered" }
  },
  // Object: What was acted upon
  "object": {
    // ... generated based on scenario
  },
  // Result: Outcome of the action
  "result": {
    // ... generated based on requirements
  },
  // Context: Additional context
  "context": {
    // ... generated based on hierarchy
  },
  "timestamp": "{{ISO8601Timestamp}}"
}
```

## Best Practices

When generating statements:

1. **Use standard verbs** - Prefer ADL/cmi5 verbs from the registry
2. **Include all required fields** - actor, verb, object at minimum
3. **Use proper URIs** - Activity IDs should be valid, stable URLs
4. **Follow interaction type rules** - Match response format to interaction type
5. **Include helpful comments** - Annotate generated JSON for clarity

## Example Interaction

User: "Generate xAPI for a multiple choice quiz question"

Response flow:
1. Ask about actor identification
2. Ask about question details (text, options, correct answer)
3. Ask about parent quiz context
4. Ask about scoring requirements
5. Generate complete statement with example

## Related Skills

Consult the xAPI Specification skill for:
- Complete verb registry
- Interaction type formats
- Activity type URIs
- cmi5 requirements
