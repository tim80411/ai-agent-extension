// 全域設定檔載入與驗證。
//
// 位置優先序：$PM_TOOLKIT_CONFIG > $XDG_CONFIG_HOME/pm-toolkit/config.yaml > ~/.config/pm-toolkit/config.yaml
// 刻意放 ~/.config 而不是 ~/.claude——~/.claude 是 Claude Code 管理的目錄，
// 使用者自己的設定不該跟工具的安裝狀態混在一起。

import { readFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { parseYaml, YamlError } from './yaml.mjs';

export class ConfigError extends Error {}

// file-based 是本 plugin 唯一「會動手」的 provider；其餘只做辨識與轉介。
export const PROVIDERS = {
  'file-based': { handled: true },
  jira: { handled: false, hint: '改用 jira-cli skill（或 Atlassian MCP）操作' },
  github: { handled: false, hint: '改用 `gh issue` / GitHub MCP 操作' },
  linear: { handled: false, hint: 'Linear 專案請走 Linear 自己的工具' },
};

export function configPath() {
  if (process.env.PM_TOOLKIT_CONFIG) return process.env.PM_TOOLKIT_CONFIG;
  const base = process.env.XDG_CONFIG_HOME || join(homedir(), '.config');
  return join(base, 'pm-toolkit', 'config.yaml');
}

export function configDir() {
  return dirname(configPath());
}

export function counterPathFor(profileName) {
  return join(configDir(), 'counters', `${profileName}.counter`);
}

export function lockDirFor(profileName) {
  return join(configDir(), 'counters', `${profileName}.lock`);
}

const DEFAULT_STATUS = { initial: 'Backlog', done: 'Done', enum: ['Backlog', 'Todo', 'In Progress', 'Done'] };

export async function loadConfig() {
  const path = configPath();
  let raw;
  try {
    raw = await readFile(path, 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT') {
      throw new ConfigError(
        `找不到設定檔：${path}\n` +
          `跑 \`node <plugin>/scripts/pm-config.mjs init\` 產一份範本，或設 $PM_TOOLKIT_CONFIG 指向現有的。`,
      );
    }
    throw e;
  }

  let doc;
  try {
    doc = parseYaml(raw);
  } catch (e) {
    if (e instanceof YamlError) throw new ConfigError(`${path}\n${e.message}`);
    throw e;
  }

  if (!doc || typeof doc !== 'object' || Array.isArray(doc)) {
    throw new ConfigError(`${path}：頂層必須是 map`);
  }
  const profiles = doc.profiles;
  if (!profiles || typeof profiles !== 'object' || Array.isArray(profiles)) {
    throw new ConfigError(`${path}：缺少 \`profiles:\` 區塊（或它不是 map）`);
  }

  const defaults = doc.defaults ?? {};
  const resolved = {};
  for (const [name, rawProfile] of Object.entries(profiles)) {
    if (!rawProfile || typeof rawProfile !== 'object' || Array.isArray(rawProfile)) {
      throw new ConfigError(`${path}：profile \`${name}\` 不是 map`);
    }
    resolved[name] = normalizeProfile(name, { ...defaults, ...rawProfile }, path);
  }

  return { path, version: doc.version ?? 1, defaults, profiles: resolved };
}

function normalizeProfile(name, p, path) {
  const provider = p.provider ?? 'file-based';
  if (!PROVIDERS[provider]) {
    throw new ConfigError(
      `${path}：profile \`${name}\` 的 provider \`${provider}\` 不認得；` +
        `可用：${Object.keys(PROVIDERS).join(', ')}`,
    );
  }

  const out = { name, provider, match: p.match ?? {}, raw: p };

  if (provider !== 'file-based') return out;

  if (!p.id_prefix) throw new ConfigError(`${path}：profile \`${name}\` 缺 \`id_prefix\``);
  if (!/^[A-Za-z][A-Za-z0-9_]*$/.test(String(p.id_prefix))) {
    throw new ConfigError(`${path}：profile \`${name}\` 的 id_prefix \`${p.id_prefix}\` 只能用英數與底線且開頭為字母`);
  }

  const status = { ...DEFAULT_STATUS, ...(p.status ?? {}) };
  if (Array.isArray(status.enum) && status.enum.length) {
    for (const key of ['initial', 'done']) {
      if (!status.enum.includes(status[key])) {
        throw new ConfigError(
          `${path}：profile \`${name}\` 的 status.${key} = \`${status[key]}\` 不在 status.enum 裡`,
        );
      }
    }
  }

  out.issuesRoot = p.issues_root ?? 'issues';
  out.idPrefix = String(p.id_prefix);
  out.grouping = p.grouping ?? null; // 例如 milestone / epic；null = 不分組
  out.defaultGroup = p.default_group ?? (out.grouping ? 'uncategorized' : null);
  out.requireExistingGroup = p.require_existing_group ?? true;
  out.status = status;
  out.sections = p.sections ?? ['背景', 'AC', '範圍外'];
  out.createCmd = p.create_cmd ?? null; // 專案自帶工具時，skill 應優先用它
  out.frontmatterExtra = p.frontmatter_extra ?? {};
  out.recordBranch = p.record_branch ?? true;
  return out;
}
