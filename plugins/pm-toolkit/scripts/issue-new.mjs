#!/usr/bin/env node
// 通用建單：發號 + 建資料夾 + 依 profile 產 frontmatter 骨架。
//
// 用途是補掉「專案沒有自己的發號工具時只能手動猜號」這個洞——手動 find 最大號 +1
// 在多 worktree／併發下必撞。專案若已有自己的工具（profile 的 create_cmd），
// 本腳本預設讓位，因為那支才是該專案的權威。
//
// 用法：
//   node issue-new.mjs "<title>" [--group <g>] [--parent <ID>] [--label <l>]... [--profile <p>]
//                               [--dry-run] [--json] [--force]

import { mkdir, writeFile, readdir, access } from 'node:fs/promises';
import { join, relative, resolve } from 'node:path';
import { loadConfig, PROVIDERS, counterPathFor, lockDirFor, ConfigError } from './lib/config.mjs';
import { resolveProfile, repoRoot, currentBranch } from './lib/profile.mjs';
import { allocateNumber, readCounter, scanMaxIssueNumber } from './lib/allocator.mjs';
import { slugify, renderIndexMd } from './lib/render.mjs';

function parseArgs(argv) {
  const out = { title: null, labels: [], group: null, parent: null, profile: null, dryRun: false, json: false, force: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const need = () => {
      const v = argv[++i];
      if (v === undefined) throw new ConfigError(`${a} 後面缺值`);
      return v;
    };
    if (a === '--label') out.labels.push(need());
    else if (a === '--parent') out.parent = need();
    else if (a === '--profile') out.profile = need();
    else if (a === '--dry-run') out.dryRun = true;
    else if (a === '--json') out.json = true;
    else if (a === '--force') out.force = true;
    else if (a === '--group' || a === '--milestone' || a === '--epic') out.group = need();
    else if (a.startsWith('--')) throw new ConfigError(`不認得的參數：${a}`);
    else if (out.title === null) out.title = a;
    else throw new ConfigError(`多餘的參數：${a}（title 請用引號包起來）`);
  }
  return out;
}

const exists = (p) => access(p).then(() => true, () => false);

function today() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

// 子單巢狀在父單資料夾下，所以要先把父單找出來
async function findIssueDir(root, prefix, id) {
  const want = new RegExp(`^${id.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}-`);
  let entries;
  try {
    entries = await readdir(root, { recursive: true, withFileTypes: true });
  } catch (e) {
    if (e.code === 'ENOENT') return null;
    throw e;
  }
  for (const e of entries) {
    if (!e.isDirectory()) continue;
    if (want.test(e.name)) return join(e.parentPath ?? e.path, e.name);
  }
  return null;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.title) {
    throw new ConfigError('缺 title。用法：issue-new.mjs "<title>" [--group <g>] [--parent <ID>] [--label <l>]...');
  }

  const config = await loadConfig();
  const { profile, reason } = await resolveProfile(config, { explicit: args.profile });

  const meta = PROVIDERS[profile.provider];
  if (!meta.handled) {
    process.stderr.write(
      `profile \`${profile.name}\` 的 provider 是 \`${profile.provider}\`，不是檔案式 tracker。\n${meta.hint}\n`,
    );
    process.exit(2);
  }

  if (profile.createCmd && !args.force) {
    process.stderr.write(
      `profile \`${profile.name}\` 已指定專案自帶的建立工具：\n  ${profile.createCmd} "${args.title}"\n` +
        `那支才是該專案的權威（發號規則可能不同）。真的要用內建發號請加 --force。\n`,
    );
    process.exit(3);
  }

  const base = (await repoRoot(process.cwd())) ?? process.cwd();
  const issuesRoot = resolve(base, profile.issuesRoot);

  // 決定落地目錄：有 --parent 就巢狀進父單，否則進分組資料夾
  let targetParent;
  let group = args.group ?? profile.defaultGroup;
  if (args.parent) {
    const dir = await findIssueDir(issuesRoot, profile.idPrefix, args.parent);
    if (!dir) throw new ConfigError(`找不到父單 \`${args.parent}\` 於 ${issuesRoot}`);
    targetParent = dir;
    if (args.group) {
      process.stderr.write(`提醒：--group 被忽略，子單的分組繼承父單（${relative(issuesRoot, dir)}）\n`);
    }
    group = profile.grouping ? relative(issuesRoot, dir).split(/[\\/]/)[0] : null;
  } else if (profile.grouping) {
    targetParent = join(issuesRoot, group);
    if (profile.requireExistingGroup && !(await exists(targetParent))) {
      let avail = [];
      try {
        avail = (await readdir(issuesRoot, { withFileTypes: true })).filter((e) => e.isDirectory()).map((e) => e.name);
      } catch {
        // issuesRoot 還不存在
      }
      throw new ConfigError(
        `分組目錄不存在：${targetParent}\n可用的 ${profile.grouping}：${avail.join(', ') || '(無)'}\n` +
          `（要自動建請在 profile 設 require_existing_group: false）`,
      );
    }
  } else {
    targetParent = issuesRoot;
  }

  const counterPath = counterPathFor(profile.name);
  const lockDir = lockDirFor(profile.name);

  if (args.dryRun) {
    const n = Math.max(await readCounter(counterPath), await scanMaxIssueNumber(issuesRoot, profile.idPrefix)) + 1;
    const id = `${profile.idPrefix}-${n}`;
    const path = join(targetParent, `${id}-${slugify(args.title)}`, 'index.md');
    process.stdout.write(`[dry-run] ${id}\n[dry-run] ${path}\n[dry-run] profile=${profile.name}（${reason}）\n`);
    return;
  }

  const n = await allocateNumber({ counterPath, lockDir, issuesRoot, prefix: profile.idPrefix });
  const id = `${profile.idPrefix}-${n}`;
  const dir = join(targetParent, `${id}-${slugify(args.title)}`);
  const indexPath = join(dir, 'index.md');

  const branch = profile.recordBranch ? await currentBranch(process.cwd()) : null;
  const content = renderIndexMd({
    id,
    title: args.title,
    status: profile.status.initial,
    groupKey: profile.grouping,
    group,
    labels: args.labels,
    today: today(),
    branch,
    sections: profile.sections,
    extra: profile.frontmatterExtra,
  });

  await mkdir(dir, { recursive: true });
  await writeFile(indexPath, content, { flag: 'wx' }); // wx：已存在就炸，不覆蓋既有 issue

  if (args.json) {
    process.stdout.write(`${JSON.stringify({ id, path: indexPath, dir, profile: profile.name, group })}\n`);
  } else {
    process.stdout.write(`${id}\n${indexPath}\n`);
  }
}

main().catch((e) => {
  process.stderr.write(`${e instanceof ConfigError ? e.message : (e.stack ?? e.message)}\n`);
  process.exit(1);
});
