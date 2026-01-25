# Material Templates for xAPI Statement Generation

Ready-to-use templates for collecting materials in common assessment scenarios.

## Quiz/Assessment Template

### Static Materials (Pre-configured)

```yaml
assessment:
  id: "https://{domain}/assessments/{assessment-id}"
  name:
    en-US: "{Assessment Title}"
  description:
    en-US: "{Assessment Description}"
  type: "http://adlnet.gov/expapi/activities/assessment"

  # Scoring configuration
  scoring:
    max_score: 100
    min_score: 0
    passing_score: 80  # For passed/failed determination

  # Parent context
  parent:
    id: "https://{domain}/courses/{course-id}"
    type: "http://adlnet.gov/expapi/activities/course"

questions:
  - id: "https://{domain}/questions/{question-id}"
    text: "{Question text}"
    interaction_type: "choice"  # choice, true-false, fill-in, etc.
    choices:
      - id: "a"
        text: "{Option A}"
      - id: "b"
        text: "{Option B}"
    correct_response: "a"
    weight: 10  # Points for this question
```

### Dynamic Materials (Runtime)

```yaml
actor:
  account:
    homePage: "https://{lms-domain}"
    name: "{user-id}"
  name: "{display-name}"  # Optional

session:
  registration: "{uuid}"  # Unique per attempt
  session_id: "{uuid}"    # For cmi5
  started_at: "{ISO-8601-timestamp}"

responses:
  - question_id: "{question-id}"
    response: "{user-response}"
    timestamp: "{ISO-8601-timestamp}"
    duration: "PT{seconds}S"

result:
  raw_score: 85
  scaled_score: 0.85
  success: true
  completion: true
  total_duration: "PT15M30S"
```

## Single Question Template

### Static Materials

```yaml
question:
  id: "https://{domain}/questions/{question-id}"
  name:
    en-US: "{Question title or number}"
  description:
    en-US: "{Full question text}"
  type: "http://adlnet.gov/expapi/activities/cmi.interaction"

  interaction:
    type: "choice"  # See interaction types reference
    choices:
      - id: "opt1"
        description:
          en-US: "{Option 1 text}"
      - id: "opt2"
        description:
          en-US: "{Option 2 text}"
    correct_responses:
      - "opt1"

  parent:
    id: "https://{domain}/assessments/{assessment-id}"
```

### Dynamic Materials

```yaml
actor:
  account:
    homePage: "https://{lms-domain}"
    name: "{user-id}"

response:
  value: "opt1"
  timestamp: "2024-01-15T10:30:00.000Z"
  duration: "PT45S"

evaluation:
  success: true
  score:
    scaled: 1.0
    raw: 1
    max: 1
```

## Course Completion Template

### Static Materials

```yaml
course:
  id: "https://{domain}/courses/{course-id}"
  name:
    en-US: "{Course Title}"
  description:
    en-US: "{Course Description}"
  type: "http://adlnet.gov/expapi/activities/course"

modules:
  - id: "https://{domain}/modules/{module-id}"
    name:
      en-US: "{Module Title}"
    type: "http://adlnet.gov/expapi/activities/module"
```

### Dynamic Materials

```yaml
actor:
  account:
    homePage: "https://{lms-domain}"
    name: "{user-id}"

completion:
  timestamp: "2024-01-15T15:00:00.000Z"
  duration: "PT2H30M"

progress:
  modules_completed: 5
  total_modules: 5
```

## cmi5 AU Session Template

### Static Materials (LMS Provided)

```yaml
au:
  id: "https://{domain}/au/{au-id}"
  name:
    en-US: "{AU Title}"
  type: "https://w3id.org/xapi/cmi5/activitytype/block"

course:
  id: "https://{domain}/courses/{course-id}"

launch:
  mode: "Normal"  # Normal, Browse, Review
  move_on: "Passed"  # Passed, Completed, CompletedAndPassed, etc.
  mastery_score: 0.8
  launch_url: "https://{content-domain}/au/{au-id}?token={token}"
```

### Dynamic Materials (Runtime)

```yaml
session:
  registration: "{uuid}"
  session_id: "{uuid}"

events:
  launched:
    timestamp: "2024-01-15T10:00:00.000Z"
  initialized:
    timestamp: "2024-01-15T10:00:05.000Z"
  completed:
    timestamp: "2024-01-15T10:15:00.000Z"
    duration: "PT14M55S"
  passed:
    timestamp: "2024-01-15T10:15:01.000Z"
    score:
      scaled: 0.92
  terminated:
    timestamp: "2024-01-15T10:15:02.000Z"
    duration: "PT15M02S"
```

## Interaction Type Templates

### True/False

```yaml
interaction:
  type: "true-false"
  correct_response: "true"

# Response
response: "true"
success: true
```

### Multiple Choice (Single Selection)

```yaml
interaction:
  type: "choice"
  choices:
    - id: "a"
      text: "Option A"
    - id: "b"
      text: "Option B"
    - id: "c"
      text: "Option C"
  correct_response: "b"

# Response
response: "b"
success: true
```

### Multiple Choice (Multiple Selection)

```yaml
interaction:
  type: "choice"
  choices:
    - id: "a"
      text: "Option A"
    - id: "b"
      text: "Option B"
    - id: "c"
      text: "Option C"
  correct_response: "a[,]c"  # Both A and C are correct

# Response
response: "a[,]c"
success: true
```

### Fill-in (Short Answer)

```yaml
interaction:
  type: "fill-in"
  correct_responses:
    - "{case_matters=false}experience api"
    - "{case_matters=false}xapi"

# Response
response: "Experience API"
success: true
```

### Matching

```yaml
interaction:
  type: "matching"
  source:
    - id: "1"
      text: "Term 1"
    - id: "2"
      text: "Term 2"
  target:
    - id: "a"
      text: "Definition A"
    - id: "b"
      text: "Definition B"
  correct_response: "1[.]a[,]2[.]b"

# Response
response: "1[.]a[,]2[.]b"
success: true
```

### Sequencing

```yaml
interaction:
  type: "sequencing"
  choices:
    - id: "step1"
      text: "First step"
    - id: "step2"
      text: "Second step"
    - id: "step3"
      text: "Third step"
  correct_response: "step1[,]step2[,]step3"

# Response
response: "step1[,]step2[,]step3"
success: true
```

### Numeric

```yaml
interaction:
  type: "numeric"
  correct_response: "42[:]42"  # Exact value
  # Or range: "40[:]45"

# Response
response: "42"
success: true
```

### Likert (No Correct Answer)

```yaml
interaction:
  type: "likert"
  scale:
    - id: "1"
      text: "Strongly Disagree"
    - id: "2"
      text: "Disagree"
    - id: "3"
      text: "Neutral"
    - id: "4"
      text: "Agree"
    - id: "5"
      text: "Strongly Agree"
  # No correct_response for Likert

# Response
response: "4"
success: null  # No success/failure for opinions
```
