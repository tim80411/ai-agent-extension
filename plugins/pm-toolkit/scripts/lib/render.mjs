// slug 與 index.md 骨架產出。骨架的欄位與分段由 profile 決定，
// 這樣不同專案（TIM- 的 milestone 制 vs 別的 epic 制）能共用同一支腳本。

// slug 僅供人讀、可有損；唯一性由 ID 保證，所以截斷、去前綴都無所謂。
export function slugify(title) {
  return title
    .replace(/^\s*\[[^\]]*\]\s*/, '') // 去開頭 [類型] 前綴
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, '-') // 非字母數字 → -（\p{L} 保留 CJK）
    .replace(/^-+|-+$/g, '')
    .slice(0, 40)
    .replace(/-+$/g, ''); // 截斷後可能又留下尾巴的 -
}

function yamlScalar(v) {
  if (v === null || v === undefined || v === '') return '';
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) return `[${v.map((x) => JSON.stringify(String(x))).join(', ')}]`;
  const s = String(v);
  // 純安全字元才裸寫，其餘一律引號，避免 : # 等把 YAML 弄壞
  return /^[\w./-]+$/.test(s) ? s : JSON.stringify(s);
}

export function renderIndexMd({ id, title, status, groupKey, group, labels, today, branch, sections, extra }) {
  const fields = [
    ['id', id],
    ['title', title],
    ['status', status],
  ];
  if (groupKey) fields.push([groupKey, group]);
  fields.push(
    ['labels', labels ?? []],
    ['created', today],
    ['updated', today],
    ['completed', null],
    ['related', []],
    ['blocks', []],
    ['blocked_by', []],
  );
  if (branch) fields.push(['git_branch', branch]);
  for (const [k, v] of Object.entries(extra ?? {})) fields.push([k, v]);

  const fm = fields.map(([k, v]) => `${k}: ${yamlScalar(v)}`.trimEnd()).join('\n');
  const body = (sections ?? []).length
    ? sections.map((s) => `## ${s}\n\n<!-- 待填 -->\n`).join('\n')
    : '<!-- 描述、AC、範圍寫這裡 -->\n';

  return `---\n${fm}\n---\n\n# ${title}\n\n${body}`;
}
