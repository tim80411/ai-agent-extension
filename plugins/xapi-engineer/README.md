# xAPI Engineer

A Claude Code plugin for xAPI statement engineering in educational assessment contexts. Analyze prompts, generate valid xAPI statements, and validate compliance with xAPI specification and cmi5 profile.

## Features

### Skills

- **xAPI Specification** - Complete reference for xAPI statement structure, verbs, activity types, interaction types, and cmi5 profile
- **Prompt Engineering for Assessment** - Analyze prompts to identify required materials for xAPI statement generation

### Commands

- `/xapi-engineer:generate` - Generate xAPI statements through interactive dialogue
- `/xapi-engineer:validate` - Validate xAPI statements for compliance
- `/xapi-engineer:analyze` - Analyze scenarios to identify required materials

### Agents

- **xapi-designer** - Proactively suggests xAPI statement designs when working with educational assessment code

## Installation

### Option 1: Global Installation

Copy the plugin to your Claude plugins directory:

```bash
# The plugin is already installed at:
~/.claude/plugins/xapi-engineer/
```

### Option 2: Project-Specific

Copy to your project's `.claude-plugin/` directory or use:

```bash
claude --plugin-dir /path/to/xapi-engineer
```

## Usage

### Generate xAPI Statements

```
/xapi-engineer:generate quiz completion tracking
```

The command will guide you through:
1. Actor identification setup
2. Activity type selection
3. Result structure definition
4. Context hierarchy configuration

### Validate Statements

```
/xapi-engineer:validate path/to/statement.json
```

Or paste JSON directly when prompted. Validation includes:
- Structural validation (required fields)
- Vocabulary validation (ADL/cmi5 verbs)
- Interaction type validation
- cmi5 compliance checks

### Analyze Scenarios

```
/xapi-engineer:analyze "Track when students answer quiz questions"
```

Returns:
- xAPI component mapping
- Required materials checklist
- Data source identification
- Implementation hints

## xAPI Quick Reference

### Statement Structure

```json
{
  "actor": {
    "account": {
      "homePage": "https://lms.example.com",
      "name": "user123"
    }
  },
  "verb": {
    "id": "http://adlnet.gov/expapi/verbs/answered",
    "display": { "en-US": "answered" }
  },
  "object": {
    "id": "https://example.com/questions/q1",
    "definition": {
      "type": "http://adlnet.gov/expapi/activities/cmi.interaction",
      "interactionType": "choice"
    }
  },
  "result": {
    "response": "a",
    "success": true,
    "score": { "scaled": 1.0 }
  }
}
```

### Common Verbs

| Verb | URI | Use Case |
|------|-----|----------|
| answered | `http://adlnet.gov/expapi/verbs/answered` | Question response |
| completed | `http://adlnet.gov/expapi/verbs/completed` | Activity completion |
| passed | `http://adlnet.gov/expapi/verbs/passed` | Met criteria |
| failed | `http://adlnet.gov/expapi/verbs/failed` | Did not meet criteria |
| attempted | `http://adlnet.gov/expapi/verbs/attempted` | Started activity |

### Interaction Types

| Type | Description |
|------|-------------|
| choice | Multiple choice questions |
| true-false | Binary choice |
| fill-in | Short text answer |
| matching | Pair matching |
| sequencing | Ordering items |
| likert | Scale rating |
| numeric | Number input |

## Resources

- [xAPI Specification](https://github.com/adlnet/xAPI-Spec)
- [ADL Vocabulary](https://registry.tincanapi.com/)
- [cmi5 Specification](https://github.com/AICC/CMI-5_Spec_Current)

## License

MIT
