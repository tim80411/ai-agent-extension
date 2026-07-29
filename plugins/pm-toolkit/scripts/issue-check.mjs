#!/usr/bin/env node
// 結構稽核：檔案式 tracker 會累積的「熵」，用一支指令抓出來。
//
// 為什麼需要它：這種 tracker 靠人手維護，錯誤都是靜默的——frontmatter 少一欄、
// 搬了資料夾卻沒改 grouping 欄、A 寫了 blocks B 但 B 沒回指。這些不會有人報錯，
// 只會讓之後的 grep 與工具悄悄失準。
//
// 每一條檢查都對應真的踩過的坑，不是為了嚴格而嚴格：
//   1. frontmatter 欄位齊全（缺欄讓 grep 與工具失準）
//   2. status 在 profile 宣告的 enum 內
//   3. id 唯一，且與所在資料夾的前綴一致
//   4. grouping 欄 == layer-1 資料夾名（搬 milestone 只搬檔沒改欄是最常見的漂移）
//   5. status==done ⇔ completed 有值
//   6. 關係欄雙向：A blocks B ⇒ B blocked_by A；related 互指；指到的 ID 要存在
//   7. INDEX（若有）與卡雙向都不漏
//
// 用法：node issue-check.mjs [--profile <p>] [--json]
// exit 0 = 乾淨、1 = 有問題、2 = 非檔案式 provider、4 = 找不到 profile（由 loadConfig 丟）

import { readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { loadConfig, PROVIDERS, ConfigError } from './lib/config.mjs';
import { resolveProfile, repoRoot } from './lib/profile.mjs';
import { loadCards, field, listField } from './lib/cards.mjs';

// renderIndexMd 寫出來的欄位就是「齊全」的定義——工具產的骨架與稽核的期待必須是同一組，
// 否則新卡一建出來就不合格。
const BASE_FIELDS = ['id', 'title', 'status', 'labels', 'created', 'updated', 'completed',
  'related', 'blocks', 'blocked_by'];

async function main() {
  const argv = process.argv.slice(2);
  const json = argv.includes('--json');
  const pi = argv.indexOf('--profile');
  const config = await loadConfig();
  const { profile } = await resolveProfile(config, { explicit: pi >= 0 ? argv[pi + 1] : null });

  const meta = PROVIDERS[profile.provider];
  if (!meta.handled) {
    process.stderr.write(`profile \`${profile.name}\` 的 provider 是 \`${profile.provider}\`。\n${meta.hint}\n`);
    process.exit(2);
  }

  const base = (await repoRoot(process.cwd())) ?? process.cwd();
  const issuesRoot = resolve(base, profile.issuesRoot);
  const cards = await loadCards(issuesRoot, profile.idPrefix);
  const problems = [];
  const byId = new Map();

  const want = profile.grouping ? [...BASE_FIELDS, profile.grouping] : BASE_FIELDS;
  for (const c of cards) {
    for (const k of want) {
      if (field(c.fm, k) === null) problems.push(`${c.rel}：缺 frontmatter 欄位 \`${k}\``);
    }
    if (byId.has(c.id)) problems.push(`${c.id} 重複：${c.rel} 與 ${byId.get(c.id).rel}`);
    byId.set(c.id, c);

    const status = field(c.fm, 'status');
    if (profile.status.enum?.length && !profile.status.enum.includes(status)) {
      problems.push(`${c.id}：status \`${status}\` 不在 enum [${profile.status.enum.join(', ')}]`);
    }

    const dirName = c.parts[c.parts.length - 2];
    if (!dirName?.startsWith(`${c.id}-`)) problems.push(`${c.id}：資料夾名 \`${dirName}\` 與 id 不符`);

    if (profile.grouping) {
      const declared = field(c.fm, profile.grouping);
      if (c.parts[0] !== declared) {
        problems.push(`${c.id}：layer-1 資料夾 \`${c.parts[0]}\` ≠ ${profile.grouping} \`${declared}\``);
      }
    }

    const done = status === profile.status.done;
    const completed = field(c.fm, 'completed');
    if (done && !completed) problems.push(`${c.id}：status=${profile.status.done} 但 completed 空白`);
    if (!done && completed) problems.push(`${c.id}：status=${status} 卻填了 completed=${completed}`);
  }

  // 關係欄雙向。單向的相依從另一邊 grep 看不到，而人通常只從自己手上那張卡看出去。
  const pairs = [['blocks', 'blocked_by'], ['blocked_by', 'blocks'], ['related', 'related']];
  for (const c of cards) {
    for (const [from, back] of pairs) {
      for (const t of listField(c.fm, from)) {
        const other = byId.get(t);
        if (!other) problems.push(`${c.id} ${from} ${t}，但 ${t} 不存在`);
        else if (!listField(other.fm, back).includes(c.id)) {
          problems.push(`${c.id} ${from} ${t}，但 ${t} 的 ${back} 沒有 ${c.id}`);
        }
      }
    }
  }

  // INDEX 是快照不是 SSOT，但「快照漏了一張卡」等於那張卡在導覽上不存在。
  const indexPath = join(issuesRoot, 'INDEX.md');
  const index = await readFile(indexPath, 'utf8').catch(() => null);
  if (index !== null) {
    const re = new RegExp(`${profile.idPrefix}-\\d+`, 'g');
    for (const t of new Set(index.match(re) ?? [])) {
      if (!byId.has(t)) problems.push(`INDEX.md 提到 ${t}，但沒有這張卡`);
    }
    for (const c of cards) {
      if (!new RegExp(`\\b${c.id}\\b`).test(index)) problems.push(`${c.id} 沒有出現在 INDEX.md`);
    }
  }

  if (json) {
    process.stdout.write(`${JSON.stringify({
      profile: profile.name, issues_root: issuesRoot, cards: cards.length,
      ok: problems.length === 0, problems,
    }, null, 2)}\n`);
  } else {
    process.stdout.write(`=== 稽核 ${cards.length} 張卡（profile ${profile.name}）===\n`);
    if (problems.length) {
      process.stdout.write(`${problems.sort().map((p) => `❌ ${p}`).join('\n')}\n`);
    } else {
      for (const c of cards) {
        const g = profile.grouping ? `  ${field(c.fm, profile.grouping)}` : '';
        process.stdout.write(`  ${c.id.padEnd(10)} ${String(field(c.fm, 'status')).padEnd(12)}${g}\n`);
      }
      process.stdout.write('✅ 全部通過\n');
    }
  }
  if (problems.length) process.exit(1);
}

main().catch((e) => {
  process.stderr.write(`${e instanceof ConfigError ? e.message : (e.stack ?? e.message)}\n`);
  process.exit(e instanceof ConfigError ? 4 : 1);
});
