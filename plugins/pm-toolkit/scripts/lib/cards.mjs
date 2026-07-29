// 讀 issue 卡的 frontmatter。issue-check / issue-reconcile 共用。
//
// 這裡刻意只做「取出 frontmatter 的純量欄位」，不做完整 YAML 解析——
// 卡的 frontmatter 是扁平的 key: value，而 lib/yaml.mjs 的受控子集是給設定檔用的，
// 拿來解卡會在 `title: "[Bug] a: b"` 這種值上吵起來。

import { readdir, readFile } from 'node:fs/promises';
import { join, relative, sep } from 'node:path';

/**
 * 只剝第一個 `---` 區塊。
 * ⚠️ 不可以用 split('---') 或「刪掉所有 --- 行」——markdown body 裡的水平線也是 `---`，
 * 那會把內文捲進 frontmatter（或製造假差異）。
 */
export function frontmatterOf(text) {
  if (!text.startsWith('---\n')) return null;
  const end = text.indexOf('\n---\n', 3);
  return end === -1 ? null : text.slice(4, end + 1);
}

/**
 * 取一個純量欄位。
 * ⚠️ 用 `[ \t]*` 不是 `\s*`——`\s` 會吃掉換行，把下一行捲進捕獲組。
 * 尾端 `#` 之後視為註解（卡上常用它註記關係欄的理由）。
 */
export function field(fm, key) {
  const m = fm.match(new RegExp(`^${key}:[ \\t]*(.*)$`, 'm'));
  if (!m) return null;
  return m[1].split('#')[0].trim();
}

/** 從一個扁平陣列欄位（`[A, B]` 或 `["A", "B"]`）取出元素。 */
export function listField(fm, key) {
  const raw = field(fm, key);
  if (!raw) return [];
  return raw
    .replace(/^\[|\]$/g, '')
    .split(',')
    .map((s) => s.trim().replace(/^["']|["']$/g, ''))
    .filter(Boolean);
}

/**
 * 遞迴掃 issuesRoot 底下所有 `<PREFIX>-<n>-<slug>/index.md`。
 * 隱藏目錄用**相對路徑**判斷——用絕對路徑會在「repo 本身住在某個點目錄底下」時
 * （例如 git worktree 放在 `.claude/worktrees/`）把全部卡誤濾掉。
 */
export async function loadCards(issuesRoot, prefix) {
  let entries;
  try {
    entries = await readdir(issuesRoot, { recursive: true, withFileTypes: true });
  } catch (e) {
    if (e.code === 'ENOENT') return [];
    throw e;
  }
  const out = [];
  for (const e of entries) {
    if (e.name !== 'index.md' || e.isDirectory()) continue;
    const dir = e.parentPath ?? e.path;
    const path = join(dir, 'index.md');
    const rel = relative(issuesRoot, path);
    if (rel.split(sep).some((p) => p.startsWith('.'))) continue;
    const text = await readFile(path, 'utf8');
    const fm = frontmatterOf(text);
    if (!fm) continue;
    const id = field(fm, 'id');
    if (!id || !id.startsWith(`${prefix}-`)) continue;
    out.push({ path, rel, dir, text, fm, id, parts: rel.split(sep) });
  }
  return out.sort((a, b) => num(a.id) - num(b.id));
}

export const num = (id) => Number(String(id).split('-').pop());
