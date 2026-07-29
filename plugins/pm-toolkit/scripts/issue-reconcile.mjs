#!/usr/bin/env node
// 狀態漂移對帳：卡還沒標完成，但它的實作 commit 已經進去了。
//
// 檔案式 tracker 靠人手翻狀態，必然累積這種漂移——做完了、commit 了、忘了回去改那一行。
// 這支把 git 歷史當成客觀證據來源，取代「憑印象覺得那張好像做完了」。
//
// 判準刻意收得很緊，寧可漏報也不要誤報——誤報會誘人把沒做完的卡翻成 done，
// 那比漏一張沒翻的傷害大得多：
//   · commit subject 開頭是 feat|fix|perf|refactor（docs/chore/test 不算實作）
//   · 該卡的 ID 是 subject 裡**第一個**出現的號（不是順帶提到的相關卡）
//   · commit 已進基準 ref（預設 origin/main；有 release tag 的專案用 --released <tag>）
//   · title 開頭 [Epic] 一律排除——母單只上線一片也會命中
//
// ⚠️ 前提是「實作 commit 的 subject 要帶卡號」。只讀 subject 是刻意的：讀 body 會把
//    commit 說明裡順帶提到的相關卡誤判成已完成。專案若沒有這個慣例，本指令會回 0 筆
//    ——那不是壞了，是慣例還沒建立。
//
// 用法：node issue-reconcile.mjs [--fix] [--released <tag>] [--profile <p>] [--json]
// exit 0 = 沒有候選或已修、1 = 有候選未修、2 = 非檔案式 provider、3 = 專案自帶對帳工具

import { writeFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { resolve } from 'node:path';
import { loadConfig, PROVIDERS, ConfigError } from './lib/config.mjs';
import { resolveProfile, repoRoot } from './lib/profile.mjs';
import { loadCards, field } from './lib/cards.mjs';

const pexec = promisify(execFile);
const IMPL = /^(feat|fix|perf|refactor)(\(.+?\))?!?:/;

async function git(cwd, args) {
  try {
    const { stdout } = await pexec('git', args, { cwd, maxBuffer: 64 * 1024 * 1024 });
    return stdout;
  } catch {
    return null;
  }
}

/** 基準 ref：使用者指定 > origin/main > main > HEAD。挑不到就講清楚，不要默默用 HEAD。 */
async function pickRef(cwd, explicit) {
  const cands = explicit ? [explicit] : ['origin/main', 'main', 'HEAD'];
  for (const r of cands) {
    if (await git(cwd, ['rev-parse', '--verify', '-q', r])) return r;
  }
  throw new ConfigError(`找不到可用的基準 ref（試過：${cands.join(', ')}）`);
}

async function main() {
  const argv = process.argv.slice(2);
  const json = argv.includes('--json');
  const fix = argv.includes('--fix');
  const val = (n) => (argv.indexOf(n) >= 0 ? argv[argv.indexOf(n) + 1] : null);

  const config = await loadConfig();
  const { profile } = await resolveProfile(config, { explicit: val('--profile') });

  const meta = PROVIDERS[profile.provider];
  if (!meta.handled) {
    process.stderr.write(`profile \`${profile.name}\` 的 provider 是 \`${profile.provider}\`。\n${meta.hint}\n`);
    process.exit(2);
  }
  // 與 create_cmd 同樣的讓位語意：專案自己那支才知道它的 release 慣例
  if (profile.reconcileCmd && !argv.includes('--force')) {
    process.stderr.write(
      `profile \`${profile.name}\` 已指定自帶的對帳工具：\n  ${profile.reconcileCmd}\n` +
        `那支才是該專案的權威。真的要用內建請加 --force。\n`,
    );
    process.exit(3);
  }

  const base = (await repoRoot(process.cwd())) ?? process.cwd();
  const issuesRoot = resolve(base, profile.issuesRoot);
  const ref = await pickRef(base, val('--released'));

  const log = (await git(base, ['log', '--no-merges', '--format=%H%x1f%s%x1f%cs', ref])) ?? '';
  const impl = new Map();                       // id -> { sha, subject, date }
  const idRe = new RegExp(`${profile.idPrefix}-(\\d+)`);
  for (const line of log.split('\n')) {
    if (!line) continue;
    const [sha, subject, date] = line.split('\x1f');
    if (!IMPL.test(subject)) continue;
    const m = subject.match(idRe);
    if (!m) continue;
    const id = `${profile.idPrefix}-${m[1]}`;
    if (!impl.has(id)) impl.set(id, { sha: sha.slice(0, 7), subject, date });   // 取最新那筆
  }

  const cards = await loadCards(issuesRoot, profile.idPrefix);
  const hits = cards
    .filter((c) => impl.has(c.id))
    .filter((c) => field(c.fm, 'status') !== profile.status.done)
    .filter((c) => !String(field(c.fm, 'title') ?? '').replace(/^["']/, '').startsWith('[Epic]'))
    .map((c) => ({ card: c, ...impl.get(c.id) }));

  if (json) {
    process.stdout.write(`${JSON.stringify({
      profile: profile.name, ref, scanned_impl_commits: impl.size, fixed: fix,
      candidates: hits.map((h) => ({ id: h.card.id, status: field(h.card.fm, 'status'), sha: h.sha, date: h.date, subject: h.subject })),
    }, null, 2)}\n`);
    if (!fix && hits.length) process.exit(1);
  }

  if (!json) process.stdout.write(`=== 狀態漂移對帳（基準 ref：${ref}）===\n`);
  if (!hits.length) {
    if (!json) process.stdout.write(`✅ 沒有漂移候選（掃到 ${impl.size} 個帶 ID 的實作 commit）\n`);
    if (!json && impl.size === 0) {
      process.stdout.write('   ⚠️ 一個都沒掃到，通常代表這個專案的 commit subject 不帶卡號。'
        + '\n      本指令只讀 subject（讀 body 會誤判順帶提到的卡）。\n');
    }
    return;
  }
  if (!json) {
    for (const h of hits) {
      process.stdout.write(`⚠️ ${h.card.id}  status=${field(h.card.fm, 'status')}  ← ${h.sha} ${h.date}  ${h.subject.slice(0, 70)}\n`);
    }
    process.stdout.write(`\n共 ${hits.length} 張。\n`);
  }

  if (!fix) {
    if (!json) {
      process.stdout.write('這是唯讀報告。**候選 ≠ 一定該完成**——增量修復也會命中；'
        + '確認該卡範圍全數完成再加 --fix，改完看 git diff 再 commit。\n');
    }
    process.exit(1);
  }

  for (const h of hits) {
    let s = h.card.text;
    s = s.replace(/^status:[ \t]*.*$/m, `status: ${profile.status.done}`);
    s = s.replace(/^completed:[ \t]*.*$/m, `completed: ${h.date}`);
    s = s.replace(/^updated:[ \t]*.*$/m, `updated: ${h.date}`);
    await writeFile(h.card.path, s, 'utf8');
    if (!json) process.stdout.write(`  ✏️ ${h.card.id} → ${profile.status.done}（completed: ${h.date}，依據 ${h.sha}）\n`);
  }
  if (!json) process.stdout.write('\n改完了。**跑 git diff 逐張看過再 commit**，並記得同步 INDEX。\n');
}

main().catch((e) => {
  process.stderr.write(`${e instanceof ConfigError ? e.message : (e.stack ?? e.message)}\n`);
  process.exit(e instanceof ConfigError ? 4 : 1);
});
