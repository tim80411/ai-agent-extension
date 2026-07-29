// 專案還沒登記時，掃 repo 把慣例推斷出來、寫進 config，然後繼續建單。
//
// 推斷的依據一律是「這個 repo 現存的事實」，不是預設值猜測：
//   id_prefix ← 現存 issue 資料夾的命名
//   grouping  ← 分組目錄名去對現存 index.md 的 frontmatter 欄位
//   status    ← 現存 index.md 實際出現過的值
// 推不出 id_prefix（repo 裡一張 issue 都沒有）就**不猜**——ID 是不可變主鍵，
// 猜錯會固定進 commit 與 branch。這種情況回報 NeedPrefixError 讓呼叫端問人。

import { readdir, readFile, writeFile, mkdir, access } from 'node:fs/promises';
import { join, relative, sep, dirname } from 'node:path';
import { configPath } from './config.mjs';
import { originUrl } from './profile.mjs';

export class NeedPrefixError extends Error {
  constructor(msg, detail) {
    super(msg);
    this.detail = detail;
  }
}

const ISSUE_DIR_RE = /^([A-Za-z][A-Za-z0-9_]*)-(\d+)-/;
const SKIP = new Set(['node_modules', 'dist', 'build', 'vendor', 'target', '.git']);

async function walk(dir, base, depth, maxDepth, out) {
  if (depth > maxDepth) return;
  let entries;
  try {
    entries = await readdir(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    if (!e.isDirectory() || e.name.startsWith('.') || SKIP.has(e.name)) continue;
    const full = join(dir, e.name);
    const m = ISSUE_DIR_RE.exec(e.name);
    if (m) out.push({ rel: relative(base, full), prefix: m[1], num: Number(m[2]) });
    await walk(full, base, depth + 1, maxDepth, out);
  }
}

// 所有 issue 資料夾的父目錄取最長共同前綴 → 那就是 issues root
function commonParent(rels) {
  const parts = rels.map((r) => r.split(sep).slice(0, -1));
  if (!parts.length) return '';
  let common = parts[0];
  for (const p of parts.slice(1)) {
    let i = 0;
    while (i < common.length && i < p.length && common[i] === p[i]) i++;
    common = common.slice(0, i);
  }
  return common.join(sep);
}

function parseFrontmatter(text) {
  const m = /^---\n([\s\S]*?)\n---/.exec(text);
  if (!m) return {};
  const out = {};
  for (const line of m[1].split('\n')) {
    const kv = /^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$/.exec(line);
    if (kv) out[kv[1]] = kv[2].trim().replace(/^["']|["']$/g, '');
  }
  return out;
}

async function detectCreateCmd(base) {
  let pkg;
  try {
    pkg = JSON.parse(await readFile(join(base, 'package.json'), 'utf8'));
  } catch {
    return null;
  }
  const key = Object.keys(pkg.scripts ?? {}).find((k) => /^issue[:-]?new$|^new[:-]?issue$/i.test(k));
  if (!key) return null;
  const has = (f) => access(join(base, f)).then(() => true, () => false);
  const runner = (await has('pnpm-lock.yaml')) ? 'pnpm' : (await has('yarn.lock')) ? 'yarn' : 'npm run';
  return `${runner} ${key}`;
}

export async function inferTracker(base, { idPrefix = null } = {}) {
  const found = [];
  await walk(base, base, 0, 5, found);

  let prefix = idPrefix;
  let issuesRoot;
  let grouping = null;
  let sections = null;
  let statusValues = [];
  let sampleGroup = null;

  if (found.length) {
    // 前綴取出現次數最多的，避免被單一命名怪異的資料夾帶偏
    const tally = {};
    for (const f of found) tally[f.prefix] = (tally[f.prefix] ?? 0) + 1;
    const dominant = Object.entries(tally).sort((a, b) => b[1] - a[1])[0][0];
    prefix = idPrefix ?? dominant;

    const mine = found.filter((f) => f.prefix === prefix);
    issuesRoot = commonParent(mine.map((f) => f.rel)) || '.';

    // 相對 issues root 的最小深度：1 = 沒分組層、≥2 = 有分組層
    const minDepth = Math.min(...mine.map((f) => relative(issuesRoot, f.rel).split(sep).length));
    if (minDepth >= 2) {
      const sample = mine.find((f) => relative(issuesRoot, f.rel).split(sep).length === minDepth);
      sampleGroup = relative(issuesRoot, sample.rel).split(sep)[0];
    }

    // 讀現存 index.md：分組欄位名靠「值等於分組目錄名」認出來，狀態值直接統計
    const newest = [...mine].sort((a, b) => b.num - a.num).slice(0, 30);
    for (const f of newest) {
      let text;
      try {
        text = await readFile(join(base, f.rel, 'index.md'), 'utf8');
      } catch {
        continue;
      }
      const fm = parseFrontmatter(text);
      if (fm.status) statusValues.push(fm.status);
      if (!grouping && sampleGroup) {
        const groupOfThis = relative(issuesRoot, f.rel).split(sep)[0];
        const hit = Object.entries(fm).find(([k, v]) => v === groupOfThis && k !== 'id' && k !== 'title');
        if (hit) grouping = hit[0];
      }
      if (!sections) {
        const heads = [...text.matchAll(/^##\s+(.+?)\s*$/gm)].map((h) => h[1]);
        if (heads.length) sections = heads;
      }
    }
    if (sampleGroup && !grouping) grouping = 'milestone'; // 有分組層但 frontmatter 沒對應欄位
  } else {
    issuesRoot = 'issues';
  }

  if (!prefix) {
    throw new NeedPrefixError(
      `無法推斷 ID 前綴：${base} 底下找不到任何現存的 issue 資料夾（形如 <PREFIX>-<n>-<slug>/）。\n` +
        `ID 是不可變主鍵，不猜。請帶 --id-prefix <PREFIX> 重跑，我會把它登記進設定檔。`,
      { base, issuesRoot },
    );
  }

  const uniq = [...new Set(statusValues)];
  const status = uniq.length
    ? {
        enum: uniq,
        initial: uniq.includes('Backlog') ? 'Backlog' : uniq.includes('Todo') ? 'Todo' : uniq[0],
        done: uniq.includes('Done') ? 'Done' : uniq[uniq.length - 1],
      }
    : { enum: ['Backlog', 'Todo', 'In Progress', 'Done'], initial: 'Backlog', done: 'Done' };

  const remote = (await originUrl(base))?.replace(/\.git$/, '');
  const ownerRepo = remote ? /[:/]([^/:]+\/[^/]+)$/.exec(remote)?.[1] : null;

  return {
    profileName: base.split(sep).pop(),
    idPrefix: prefix,
    issuesRoot,
    grouping,
    defaultGroup: sampleGroup ?? (grouping ? 'uncategorized' : null),
    status,
    sections: sections ?? ['背景', 'AC', '範圍外'],
    createCmd: await detectCreateCmd(base),
    match: ownerRepo ? { git_remote: ownerRepo } : { path: base },
    evidence: {
      issuesFound: found.length,
      statusSeen: uniq,
    },
  };
}

function yamlValue(v) {
  if (v === null || v === undefined) return 'null';
  if (Array.isArray(v)) return `[${v.map((x) => JSON.stringify(String(x))).join(', ')}]`;
  const s = String(v);
  return /^[\w./-]+$/.test(s) ? s : JSON.stringify(s);
}

export function renderProfileBlock(inf) {
  const provider = inf.provider ?? 'file-based';
  const L = [`  ${inf.profileName}:`, `    provider: ${provider}`];
  if (Object.keys(inf.match ?? {}).length) {
    L.push(`    match:`);
    for (const [k, v] of Object.entries(inf.match)) L.push(`      ${k}: ${yamlValue(v)}`);
  }
  if (provider !== 'file-based') {
    // 非 file-based 只記轉介所需的自由欄位
    for (const [k, v] of Object.entries(inf.settings ?? {})) L.push(`    ${k}: ${yamlValue(v)}`);
    return L.join('\n');
  }
  L.push(`    issues_root: ${yamlValue(inf.issuesRoot ?? 'issues')}`, `    id_prefix: ${yamlValue(inf.idPrefix)}`);
  if (inf.grouping) {
    L.push(`    grouping: ${yamlValue(inf.grouping)}`, `    default_group: ${yamlValue(inf.defaultGroup)}`);
  }
  L.push(
    `    status:`,
    `      initial: ${yamlValue(inf.status.initial)}`,
    `      done: ${yamlValue(inf.status.done)}`,
    `      enum: ${yamlValue(inf.status.enum)}`,
    `    sections: ${yamlValue(inf.sections)}`,
  );
  if (inf.createCmd) L.push(`    create_cmd: ${yamlValue(inf.createCmd)}`);
  return L.join('\n');
}

const EMPTY_CONFIG = `# pm-toolkit 設定檔（自動建立）
version: 1

defaults:
  provider: file-based

profiles:
`;

// 用附加而非重新序列化——重新序列化會把使用者的註解與排版全洗掉
export async function appendProfile(inf) {
  const path = configPath();
  let text;
  try {
    text = await readFile(path, 'utf8');
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
    await mkdir(dirname(path), { recursive: true });
    text = EMPTY_CONFIG;
  }

  const block = renderProfileBlock(inf);
  const lines = text.split('\n');
  const pi = lines.findIndex((l) => /^profiles:\s*$/.test(l));

  if (pi < 0) {
    text = `${text.replace(/\n*$/, '')}\n\nprofiles:\n${block}\n`;
  } else {
    // 插在 profiles 區塊的最後一行之後，別動到後面的其他頂層區塊
    let end = pi;
    for (let i = pi + 1; i < lines.length; i++) {
      if (lines[i].trim() === '') continue;
      if (/^\s/.test(lines[i])) end = i;
      else break;
    }
    lines.splice(end + 1, 0, block);
    text = lines.join('\n');
  }

  await writeFile(path, text);
  return path;
}
