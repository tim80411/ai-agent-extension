#!/usr/bin/env node
// 設定檔管理：init（產範本）／show（解析當下專案對應的 profile）／list（列出全部）。
//
// `show --json` 是給 skill 的 Step 0 用的：命中 profile 就直接拿設定，
// 省掉每次重新探勘這個 repo 的慣例；沒命中才退回人工探勘。

import { writeFile, mkdir, access } from 'node:fs/promises';
import { loadConfig, configPath, counterPathFor, PROVIDERS, ConfigError } from './lib/config.mjs';
import { resolveProfile } from './lib/profile.mjs';
import { dirname } from 'node:path';

const TEMPLATE = `# pm-toolkit 設定檔
# 位置優先序：$PM_TOOLKIT_CONFIG > $XDG_CONFIG_HOME/pm-toolkit/config.yaml > ~/.config/pm-toolkit/config.yaml
version: 1

# 每個 profile 都會先繼承 defaults，再用自己的欄位覆蓋
defaults:
  provider: file-based

profiles:
  # ── 檔案式 tracker：本 plugin 會實際動手建單 ──────────────────────
  example-project:
    provider: file-based

    # 怎麼認出「現在人在這個專案」。由上而下比對，命中就停。
    # 也可以在專案根放一個 .pm-toolkit-profile 檔（內容寫 profile 名）取代 match。
    match:
      git_remote: youruser/example-project   # 對 origin URL 做子字串比對
      path: ~/code/example-project           # 對 cwd 做前綴比對

    issues_root: issues        # 相對 repo 根
    id_prefix: EX              # ID 主鍵前綴 → EX-1、EX-2…
    grouping: milestone        # layer-1 資料夾的語意；不分組就設 null
    default_group: uncategorized
    require_existing_group: true   # false = 分組目錄不存在時自動建
    status:
      initial: Backlog
      done: Done
      enum: [Backlog, Todo, In Progress, In Review, Done, Canceled]
    sections: ["背景", "AC", "範圍外"]
    record_branch: true
    # frontmatter_extra:       # 想多塞固定欄位就寫這
    #   owner: someone

  # 專案自己有發號工具時，寫 create_cmd 讓內建發號讓位（那支才是權威）
  project-with-own-tool:
    provider: file-based
    match:
      git_remote: youruser/project-with-own-tool
    issues_root: issues
    id_prefix: PROJ
    grouping: milestone
    create_cmd: "pnpm issue:new"

  # ── 非檔案式：只做辨識與轉介，本 plugin 不動手 ────────────────────
  some-jira-project:
    provider: jira
    match:
      git_remote: yourorg/some-backend
    project_key: ABC

  some-github-project:
    provider: github
    match:
      path: ~/code/some-oss
    repo: youruser/some-oss
`;

async function cmdInit(force) {
  const path = configPath();
  const already = await access(path).then(() => true, () => false);
  if (already && !force) {
    process.stderr.write(`已存在：${path}\n要覆蓋請加 --force（會蓋掉現有內容）\n`);
    process.exit(1);
  }
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, TEMPLATE);
  process.stdout.write(`已寫入範本：${path}\n改成你自己的專案後，用 \`pm-config.mjs show\` 驗證。\n`);
}

async function cmdList(json) {
  const config = await loadConfig();
  const rows = Object.values(config.profiles).map((p) => ({
    name: p.name,
    provider: p.provider,
    id_prefix: p.idPrefix ?? null,
    issues_root: p.issuesRoot ?? null,
    create_cmd: p.createCmd ?? null,
  }));
  if (json) return void process.stdout.write(`${JSON.stringify({ config: config.path, profiles: rows }, null, 2)}\n`);
  process.stdout.write(`設定檔：${config.path}\n\n`);
  for (const r of rows) {
    const extra = r.provider === 'file-based' ? `${r.id_prefix}- @ ${r.issues_root}` : PROVIDERS[r.provider].hint;
    process.stdout.write(`  ${r.name.padEnd(24)} ${r.provider.padEnd(12)} ${extra}\n`);
  }
}

async function cmdShow(json, explicit) {
  const config = await loadConfig();
  const { profile, reason } = await resolveProfile(config, { explicit });
  const out = {
    config: config.path,
    profile: profile.name,
    matched_by: reason,
    provider: profile.provider,
    handled_by_this_plugin: PROVIDERS[profile.provider].handled,
  };
  if (profile.provider === 'file-based') {
    Object.assign(out, {
      issues_root: profile.issuesRoot,
      id_prefix: profile.idPrefix,
      grouping: profile.grouping,
      default_group: profile.defaultGroup,
      status: profile.status,
      sections: profile.sections,
      create_cmd: profile.createCmd,
      counter: counterPathFor(profile.name),
    });
  } else {
    out.hint = PROVIDERS[profile.provider].hint;
    out.settings = profile.raw;
  }
  if (json) return void process.stdout.write(`${JSON.stringify(out, null, 2)}\n`);
  for (const [k, v] of Object.entries(out)) {
    process.stdout.write(`${k.padEnd(24)} ${typeof v === 'object' && v !== null ? JSON.stringify(v) : v}\n`);
  }
}

async function main() {
  const argv = process.argv.slice(2);
  const cmd = argv[0] ?? 'show';
  const json = argv.includes('--json');
  const force = argv.includes('--force');
  const pIdx = argv.indexOf('--profile');
  const explicit = pIdx >= 0 ? argv[pIdx + 1] : null;

  if (cmd === 'init') return cmdInit(force);
  if (cmd === 'list') return cmdList(json);
  if (cmd === 'show') return cmdShow(json, explicit);
  throw new ConfigError(`不認得的指令：${cmd}（可用：init / show / list）`);
}

main().catch((e) => {
  process.stderr.write(`${e instanceof ConfigError ? e.message : (e.stack ?? e.message)}\n`);
  process.exit(1);
});
