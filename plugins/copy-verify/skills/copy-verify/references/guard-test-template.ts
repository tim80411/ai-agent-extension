/**
 * 防回歸 guard 骨架（vitest 風格）— 複製到你的專案 tests/ 後改路徑即可。
 * 換成 jest / node:test 也是同一套邏輯：走訪原始碼、剝註解、比對 BANNED_TERMS。
 *
 * 為何直接子字串比對就夠：BANNED_TERMS 只收「任何程式碼語境都不會合法出現」的 token，
 * 所以毋須 AST。裸英文技術詞不在此守備範圍（見 SKILL.md 主線 B）。
 */
import { describe, it, expect } from 'vitest'
import { readdirSync, readFileSync } from 'fs'
import { join, resolve, relative, dirname } from 'path'
import { fileURLToPath } from 'url'
import { BANNED_TERMS } from '../../src/shared/copy/glossary' // ← 改成你的 glossary 路徑

const HERE = dirname(fileURLToPath(import.meta.url))
const REPO_ROOT = resolve(HERE, '../..') // ← 依測試檔位置調整
const SCAN_ROOT = join(REPO_ROOT, 'src') // ← 要掃的原始碼根目錄

// 允許清單：定本檔本身會合法列出所有禁用字，必須跳過（測試檔若在 SCAN_ROOT 外則毋須列）
const ALLOWLIST = new Set<string>([join(SCAN_ROOT, 'shared', 'copy', 'glossary.ts')])

function collectSourceFiles(dir: string, acc: string[] = []): string[] {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name)
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === 'dist') continue
      collectSourceFiles(full, acc)
    } else if (/\.(ts|tsx)$/.test(entry.name) && !ALLOWLIST.has(full)) {
      acc.push(full)
    }
  }
  return acc
}

// 剝除註解以降低「僅出現在註解」的誤報；lookbehind 排除 :// 以保留 URL
function stripComments(code: string): string {
  return code
    .replace(/\/\*[\s\S]*?\*\//g, '') // 區塊註解 / JSDoc
    .replace(/(?<!:)\/\/[^\n]*/g, '') // 行內註解（不吃 https://）
}

describe('文案禁用詞回歸 guard（glossary SSOT）', () => {
  it('原始碼不得出現任何 BANNED_TERMS', () => {
    const violations: string[] = []
    for (const file of collectSourceFiles(SCAN_ROOT)) {
      const stripped = stripComments(readFileSync(file, 'utf8'))
      for (const { term, suggest } of BANNED_TERMS) {
        if (stripped.includes(term)) {
          violations.push(`${relative(REPO_ROOT, file)}: 「${term}」→ 改用「${suggest}」`)
        }
      }
    }
    expect(violations, `\n發現禁用詞：\n${violations.join('\n')}\n`).toEqual([])
  })
})
