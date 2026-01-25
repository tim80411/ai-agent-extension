# xAPI Context 規則參考

完整的 Context 結構規則，區分標準規範與自定義內容。

## Context 結構總覽

```
context
├── registration: UUID ─────────────── 📘 標準格式
├── contextActivities ──────────────── 📘 標準結構
│   ├── parent[]    ← 直接上層
│   ├── grouping[]  ← 間接相關
│   ├── category[]  ← 分類標籤
│   └── other[]     ← 其他關聯
├── extensions ─────────────────────── 📘 標準容器（內容自定義）
├── platform ───────────────────────── 📘 標準欄位
└── language ───────────────────────── 📘 標準欄位
```

## 標準 vs 自定義對照表

### 📘 標準規範部分（xAPI Spec 定義）

| 項目 | 說明 | 規則 |
|------|------|------|
| `context` | 頂層屬性 | 結構固定，不可更改 |
| `registration` | 追蹤單次嘗試 | 必須是 UUID v4 格式 |
| `contextActivities` | 情境活動容器 | 只能包含 parent/grouping/category/other |
| `contextActivities.parent` | 直接上層關係 | Activity 陣列 |
| `contextActivities.grouping` | 間接相關關係 | Activity 陣列 |
| `contextActivities.category` | 分類/標籤 | Activity 陣列 |
| `contextActivities.other` | 其他關聯 | Activity 陣列 |
| `extensions` | 擴充欄位容器 | Key 必須是 IRI |
| `platform` | 平台識別 | 字串 |
| `language` | 語言標籤 | RFC 5646 格式 (如 `en-US`, `zh-TW`) |

### 📙 自定義部分（你/組織定義）

| 項目 | 說明 | 設計原則 |
|------|------|----------|
| Activity ID | 活動識別碼 | 使用你控制的域名 URL |
| Activity Type | 活動類型 URI | 優先用標準，沒有才自定義 |
| Activity name/description | 活動名稱與描述 | Language Map 格式 |
| Extensions Key | 擴充欄位的 Key | 使用你控制的域名 IRI |
| Extensions Value | 擴充欄位的值 | 任意 JSON 值 |

## Context Activities 四種類型詳解

### Parent（父活動）

**用途**：表示「直接包含」此活動的上層活動

**典型場景**：
- 題目 → 測驗（題目的 parent 是測驗）
- 測驗 → 課程章節

```json
{
  "contextActivities": {
    "parent": [{
      "id": "https://example.com/quizzes/math-quiz-1",
      "objectType": "Activity",
      "definition": {
        "type": "http://adlnet.gov/expapi/activities/assessment",
        "name": { "zh-TW": "數學測驗一" }
      }
    }]
  }
}
```

### Grouping（分組活動）

**用途**：表示「間接相關」的更廣泛組織單位

**典型場景**：
- 題目 → 課程（跳過中間的測驗層級）
- 測驗 → 學習路徑

```json
{
  "contextActivities": {
    "grouping": [{
      "id": "https://example.com/courses/elementary-math",
      "objectType": "Activity",
      "definition": {
        "type": "http://adlnet.gov/expapi/activities/course",
        "name": { "zh-TW": "國小數學" }
      }
    }]
  }
}
```

### Category（分類活動）

**用途**：標記活動的「標籤」或「分類標準」，定義如何解讀此 statement

**典型場景**：
- 知識點分類
- 學科標籤
- Profile 標識（如 cmi5）

```json
{
  "contextActivities": {
    "category": [
      {
        "id": "https://example.com/knowledge-points/addition",
        "definition": {
          "type": "http://id.tincanapi.com/activitytype/knowledge-point",
          "name": { "zh-TW": "加法" }
        }
      },
      {
        "id": "https://w3id.org/xapi/cmi5/context/categories/cmi5",
        "objectType": "Activity"
      }
    ]
  }
}
```

### Other（其他活動）

**用途**：其他相關但不屬於上述三類的活動

**典型場景**：
- 推薦內容
- 相關資源
- 先修內容

## Registration 規則

### 格式要求

- 必須是 **UUID v4** 格式
- 例如：`00000000-0000-4000-8000-000000000082`

### 使用原則

| 原則 | 說明 |
|------|------|
| 一致性 | 同一次測驗嘗試的所有 statement 使用相同 UUID |
| 唯一性 | 每次新的嘗試產生新的 UUID |
| 追蹤範圍 | 用於關聯同一學習會話中的所有記錄 |

```json
{
  "context": {
    "registration": "ce909628-70d8-4edc-834a-0284739cb544"
  }
}
```

## Extensions 規則

### Key 格式要求

- **必須是 IRI**（通常是 URL）
- **使用你控制的域名**，避免與其他系統衝突

```json
{
  "extensions": {
    "https://your-company.com/xapi/extensions/school-level": "國小",
    "https://your-company.com/xapi/extensions/difficulty": 3
  }
}
```

### Value 格式

- 可以是任意 JSON 值（字串、數字、布林、物件、陣列）

### 常見自定義 Extensions

| Extension Key | 用途 | 值範例 |
|---------------|------|--------|
| `.../school-level` | 學級 | `"國小"`, `"國中"` |
| `.../difficulty` | 難度 | `1`, `2`, `3` |
| `.../question-category` | 題型分類 | `"選擇題"`, `"填空題"` |
| `.../attempt-number` | 嘗試次數 | `1`, `2`, `3` |

## Activity Type 優先順序

設計 Activity Type 時，依以下順序選擇：

### 1️⃣ ADL 官方標準（最優先）

```
http://adlnet.gov/expapi/activities/...
```

常用類型：
- `assessment` - 測驗
- `course` - 課程
- `module` - 模組
- `cmi.interaction` - 互動題目

### 2️⃣ 社群擴充（TinCan Registry）

```
http://id.tincanapi.com/activitytype/...
```

常用類型：
- `knowledge-point` - 知識點
- `subject` - 學科
- `school` - 學校

### 3️⃣ 自定義（最後選擇）

```
https://your-company.com/xapi/activitytype/...
```

**設計原則**：
1. 使用你控制的域名
2. 路徑結構清晰一致
3. 內部文件記錄定義

## Language Map 格式

### RFC 5646 語言標籤

| 標籤 | 語言 |
|------|------|
| `en-US` | 美式英語 |
| `en-GB` | 英式英語 |
| `zh-TW` | 繁體中文（台灣） |
| `zh-CN` | 簡體中文（中國） |
| `ja` | 日語 |

### 使用範例

```json
{
  "name": {
    "zh-TW": "認識加法算式",
    "en-US": "Introduction to Addition Expressions"
  },
  "description": {
    "zh-TW": "學習基本的加法運算概念"
  }
}
```

## Activity ID 設計原則

### 建議格式

```
https://{domain}/{type}/{identifier}
```

### 範例

| 類型 | ID 範例 |
|------|---------|
| 課程 | `https://lms.example.com/courses/math-101` |
| 測驗 | `https://lms.example.com/assessments/quiz-001` |
| 題目 | `https://lms.example.com/questions/q-12345` |
| 知識點 | `https://lms.example.com/knowledge-points/addition` |

### 最佳實踐

✅ **推薦**：
- 使用 HTTPS
- 使用穩定不變的 URI
- 路徑有意義且可讀
- 避免 query parameters

❌ **避免**：
- `http://example.com/activity?id=123` （含 query params）
- `urn:uuid:12345` （不透明識別碼）
- `http://example.com/quiz` （太籠統）

## 完整 Context 範例

```json
{
  "context": {
    "registration": "00000000-0000-4000-8000-000000000082",
    "contextActivities": {
      "parent": [{
        "id": "https://lms.example.com/assessments/math-quiz-1",
        "definition": {
          "type": "http://adlnet.gov/expapi/activities/assessment",
          "name": { "zh-TW": "數學測驗一" }
        }
      }],
      "grouping": [{
        "id": "https://lms.example.com/courses/elementary-math",
        "definition": {
          "type": "http://adlnet.gov/expapi/activities/course",
          "name": { "zh-TW": "國小數學" }
        }
      }],
      "category": [
        {
          "id": "https://lms.example.com/knowledge-points/addition",
          "definition": {
            "type": "http://id.tincanapi.com/activitytype/knowledge-point",
            "name": { "zh-TW": "加法" }
          }
        },
        {
          "id": "https://lms.example.com/subjects/math",
          "definition": {
            "type": "http://id.tincanapi.com/activitytype/subject",
            "name": { "zh-TW": "數學" }
          }
        }
      ]
    },
    "extensions": {
      "https://lms.example.com/xapi/extensions/school-level": "國小",
      "https://lms.example.com/xapi/extensions/grade": 1
    },
    "platform": "Example LMS",
    "language": "zh-TW"
  }
}
```

## 規則摘要

| 原則 | 說明 |
|------|------|
| 結構遵循標準 | context、contextActivities 的結構不能改變 |
| ID 自行設計 | Activity ID 使用你控制的域名 URL |
| Type 優先用標準 | ADL 官方 > TinCan Registry > 自定義 |
| Extensions 完全自由 | Key 用你的域名 IRI，Value 任意 JSON |
| Language Map | 使用 RFC 5646 語言標籤 |
| Registration | 同一嘗試使用相同 UUID |
