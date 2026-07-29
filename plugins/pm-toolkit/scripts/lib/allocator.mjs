// 防撞發號。移植自 admission-radar 的 allocator.ts，兩處通用化：
//   1. ID 前綴參數化（原本寫死 TIM-）
//   2. 計數檔改放全域 config 目錄，而非 <git-common-dir>——不是每個專案都有 git
//
// 安全性靠兩層，缺一不可：
//   - mkdir 當鎖：mkdir 在 POSIX 上是原子的，同機併發只有一個會成功
//   - next = max(計數檔, 掃描最大號) + 1：計數檔遺失、被砍、換機器都不會退號重發
// 計數檔只是加速與「跨 worktree 看得到彼此」的機制，掃描才是真正的地板。

import { readdir, readFile, writeFile, mkdir, rmdir, stat } from 'node:fs/promises';
import { dirname } from 'node:path';

export async function scanMaxIssueNumber(issuesRoot, prefix) {
  let entries;
  try {
    entries = await readdir(issuesRoot, { recursive: true });
  } catch (e) {
    if (e.code === 'ENOENT') return 0;
    throw e;
  }
  const re = new RegExp(`^${escapeRe(prefix)}-(\\d+)-`);
  let max = 0;
  for (const p of entries) {
    const base = p.split(/[\\/]/).pop() ?? '';
    const m = re.exec(base);
    if (m) max = Math.max(max, Number(m[1]));
  }
  return max;
}

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export async function readCounter(counterPath) {
  let raw;
  try {
    raw = await readFile(counterPath, 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT') return 0;
    throw e;
  }
  const n = Number.parseInt(raw.trim(), 10);
  return Number.isFinite(n) && n >= 0 ? n : 0;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export async function acquireLock(lockDir, opts = {}) {
  const staleMs = opts.staleMs ?? 30_000;
  const timeoutMs = opts.timeoutMs ?? 5_000;
  const pollMs = opts.pollMs ?? 50;
  const start = Date.now();
  await mkdir(dirname(lockDir), { recursive: true });
  for (;;) {
    try {
      await mkdir(lockDir);
      return;
    } catch (e) {
      if (e.code !== 'EEXIST') throw e;
      try {
        const st = await stat(lockDir);
        if (Date.now() - st.mtimeMs > staleMs) {
          // 殘留鎖（前一個 process 被 kill）→ 清掉重搶
          await rmdir(lockDir).catch(() => undefined);
          continue;
        }
      } catch {
        // stat 失敗＝鎖剛被別人釋放，直接重試
      }
      if (Date.now() - start > timeoutMs) {
        throw new Error(`另一個發號程序正在執行（鎖：${lockDir}）；稍候再試`);
      }
      await sleep(pollMs);
    }
  }
}

export async function releaseLock(lockDir) {
  await rmdir(lockDir).catch(() => undefined);
}

export async function allocateNumber({ counterPath, lockDir, issuesRoot, prefix }, lockOpts) {
  await acquireLock(lockDir, lockOpts);
  try {
    const counterVal = await readCounter(counterPath);
    const scanMax = await scanMaxIssueNumber(issuesRoot, prefix);
    const next = Math.max(counterVal, scanMax) + 1;
    await mkdir(dirname(counterPath), { recursive: true });
    await writeFile(counterPath, String(next));
    return next;
  } finally {
    await releaseLock(lockDir);
  }
}
