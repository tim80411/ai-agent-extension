// 把「當下在哪個專案」對應到 config 裡的某個 profile。
//
// 優先序由明確到推測，命中就停：
//   1. --profile 參數 / $PM_TOOLKIT_PROFILE
//   2. 專案內 .pm-toolkit-profile 檔（往上找到 repo 根或檔案系統根）
//   3. match.git_remote：對 origin URL 做子字串比對（同時吃 ssh 與 https 形式）
//   4. match.path：對 cwd 做前綴比對（支援 ~）
//   5. profile 名 == repo 目錄名
// 全部落空就報錯並列出可用 profile——寧可不動作，也不要猜錯專案去發號。

import { execFile } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { promisify } from 'node:util';
import { dirname, join, resolve, sep } from 'node:path';
import { ConfigError } from './config.mjs';

const exec = promisify(execFile);

async function git(cwd, args) {
  try {
    const { stdout } = await exec('git', args, { cwd });
    return stdout.trim();
  } catch {
    return null; // 沒有 git、不在 repo 裡都算正常
  }
}

export const repoRoot = (cwd) => git(cwd, ['rev-parse', '--show-toplevel']);
export const originUrl = (cwd) => git(cwd, ['remote', 'get-url', 'origin']);

// `branch --show-current` 在「剛 init、還沒有 commit」的 repo 上也答得出來；
// `rev-parse --abbrev-ref HEAD` 在那種 unborn branch 上會直接失敗。留 fallback 給 git < 2.22。
export async function currentBranch(cwd) {
  const shown = await git(cwd, ['branch', '--show-current']);
  if (shown) return shown;
  const ref = await git(cwd, ['rev-parse', '--abbrev-ref', 'HEAD']);
  return ref && ref !== 'HEAD' ? ref : null; // detached HEAD 就不記
}

function expandHome(p) {
  return p.startsWith('~') ? join(homedir(), p.slice(1)) : p;
}

async function findMarker(startDir) {
  let dir = resolve(startDir);
  for (;;) {
    try {
      const name = (await readFile(join(dir, '.pm-toolkit-profile'), 'utf8')).trim();
      if (name) return { name, at: dir };
    } catch {
      // 沒有就往上
    }
    const parent = dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

export async function resolveProfile(config, { cwd = process.cwd(), explicit = null } = {}) {
  const names = Object.keys(config.profiles);
  const pick = (name, reason) => {
    const profile = config.profiles[name];
    if (!profile) {
      throw new ConfigError(`指定的 profile \`${name}\` 不存在（${reason}）；可用：${names.join(', ') || '(無)'}`);
    }
    return { profile, reason };
  };

  const flag = explicit || process.env.PM_TOOLKIT_PROFILE;
  if (flag) return pick(flag, explicit ? '--profile 參數' : '$PM_TOOLKIT_PROFILE');

  const marker = await findMarker(cwd);
  if (marker) return pick(marker.name, `${join(marker.at, '.pm-toolkit-profile')}`);

  const url = (await originUrl(cwd))?.replace(/\.git$/, '').toLowerCase();
  if (url) {
    for (const name of names) {
      const want = config.profiles[name].match?.git_remote;
      if (want && url.includes(String(want).toLowerCase())) {
        return pick(name, `git remote 命中 \`${want}\``);
      }
    }
  }

  const here = resolve(cwd);
  for (const name of names) {
    const want = config.profiles[name].match?.path;
    if (!want) continue;
    const base = resolve(expandHome(String(want)));
    if (here === base || here.startsWith(base + sep)) {
      return pick(name, `路徑前綴命中 \`${want}\``);
    }
  }

  const root = (await repoRoot(cwd)) ?? here;
  const dirName = root.split(sep).pop();
  if (dirName && config.profiles[dirName]) {
    return pick(dirName, `目錄名 \`${dirName}\` 與 profile 同名`);
  }

  const err = new ConfigError(
    `在 ${here} 找不到對應的 profile。\n` +
      `已登記的：${names.join(', ') || '(無)'}\n` +
      `這個專案還沒登記——用 \`init-tracker-config\` skill 走一次引導式登記（它會掃 repo 推斷慣例、` +
      `跟你確認 ID 前綴，再寫進設定檔）。\n` +
      `已經登記過只是認不出來的話：加 --profile <name>、在專案根放 .pm-toolkit-profile，` +
      `或補該 profile 的 match.git_remote / match.path。`,
  );
  err.needsSetup = true;
  throw err;
}
