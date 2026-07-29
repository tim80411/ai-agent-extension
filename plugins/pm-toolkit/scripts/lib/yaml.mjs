// 受控子集的 YAML parser——零依賴，只為 pm-toolkit config 服務。
//
// 支援：巢狀 map、block sequence（純量與 map item）、flow sequence `[a, b]`、
//       單/雙引號字串、數字、true/false/null/~、`#` 註解。
// 刻意不支援：anchor/alias、multi-line scalar（| >）、flow map `{}`、多文件 `---`、tab 縮排。
//
// 「不支援」一律明確拋錯而非安靜解析錯——config 解錯會導致發錯號，寧可吵。

export class YamlError extends Error {}

function fail(n, msg) {
  throw new YamlError(`YAML 第 ${n} 行：${msg}`);
}

// 去掉行內註解，但不動引號裡的 #
function stripComment(line) {
  let out = '';
  let quote = null;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quote) {
      out += c;
      if (quote === '"' && c === '\\') {
        out += line[++i] ?? '';
        continue;
      }
      if (c === quote) quote = null;
      continue;
    }
    if (c === '"' || c === "'") {
      quote = c;
      out += c;
      continue;
    }
    // 只有前面是空白（或行首）的 # 才算註解，避免砍掉 url#frag
    if (c === '#' && (i === 0 || /\s/.test(line[i - 1]))) break;
    out += c;
  }
  return out;
}

function tokenize(text) {
  const lines = [];
  text.split(/\r?\n/).forEach((raw, idx) => {
    const n = idx + 1;
    if (/^\s*\t/.test(raw)) fail(n, '縮排含 tab；YAML 縮排只能用空白');
    if (/^\s*(---|\.\.\.)\s*$/.test(raw)) fail(n, '不支援多文件分隔（--- / ...）');
    if (/^\s*[&*]\w/.test(raw)) fail(n, '不支援 anchor / alias');
    const content = stripComment(raw).replace(/\s+$/, '');
    if (!content.trim()) return;
    lines.push({ indent: content.length - content.trimStart().length, text: content.trim(), n });
  });
  return lines;
}

// 依引號與括號深度切 flow sequence 的逗號
function splitFlow(body, n) {
  const parts = [];
  let cur = '';
  let quote = null;
  let depth = 0;
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    if (quote) {
      cur += c;
      if (quote === '"' && c === '\\') {
        cur += body[++i] ?? '';
        continue;
      }
      if (c === quote) quote = null;
      continue;
    }
    if (c === '"' || c === "'") { quote = c; cur += c; continue; }
    if (c === '[') { depth++; cur += c; continue; }
    if (c === ']') { depth--; cur += c; continue; }
    if (c === ',' && depth === 0) { parts.push(cur); cur = ''; continue; }
    cur += c;
  }
  if (quote) fail(n, '引號沒有收尾');
  if (depth !== 0) fail(n, '中括號沒有配對');
  if (cur.trim() !== '') parts.push(cur);
  return parts.map((p) => p.trim());
}

function parseScalar(s, n) {
  if (s === '' || s === '~' || s === 'null') return null;
  if (s === 'true') return true;
  if (s === 'false') return false;
  if (/^-?\d+$/.test(s)) return Number(s);
  if (/^-?\d*\.\d+$/.test(s)) return Number(s);

  if (s[0] === '|' || s[0] === '>') fail(n, '不支援 multi-line scalar（| 或 >）');
  if (s[0] === '{') fail(n, '不支援 flow map `{}`；請改用縮排巢狀');

  if (s[0] === '"') {
    if (!s.endsWith('"') || s.length < 2) fail(n, '雙引號沒有收尾');
    try {
      return JSON.parse(s);
    } catch {
      fail(n, `雙引號字串解析失敗：${s}`);
    }
  }
  if (s[0] === "'") {
    if (!s.endsWith("'") || s.length < 2) fail(n, '單引號沒有收尾');
    return s.slice(1, -1).replace(/''/g, "'");
  }
  if (s[0] === '[') {
    if (!s.endsWith(']')) fail(n, 'flow sequence 沒有收尾 ]');
    const body = s.slice(1, -1).trim();
    if (body === '') return [];
    return splitFlow(body, n).map((p) => parseScalar(p, n));
  }
  return s;
}

const KEY_RE = /^(?:"((?:[^"\\]|\\.)*)"|'((?:[^']|'')*)'|([^:]+?))\s*:(?:\s+(.*))?$/;

// 回傳 [value, 下一個未消化的 index]
function parseNode(lines, i, indent) {
  if (i >= lines.length) return [null, i];
  if (lines[i].text.startsWith('- ') || lines[i].text === '-') {
    return parseSeq(lines, i, indent);
  }
  return parseMap(lines, i, indent);
}

function parseSeq(lines, i, indent) {
  const out = [];
  while (i < lines.length && lines[i].indent === indent) {
    const { text, n } = lines[i];
    if (!text.startsWith('- ') && text !== '-') break;
    const rest = text === '-' ? '' : text.slice(2).trim();
    i++;
    if (rest === '') {
      // 值在下一層縮排
      if (i < lines.length && lines[i].indent > indent) {
        const [v, ni] = parseNode(lines, i, lines[i].indent);
        out.push(v);
        i = ni;
      } else {
        out.push(null);
      }
      continue;
    }
    // `- key: value` → 把這個 item 當成一個縮排在 indent+2 的 map
    if (KEY_RE.test(rest)) {
      const sub = [{ indent: indent + 2, text: rest, n }];
      while (i < lines.length && lines[i].indent > indent) {
        sub.push(lines[i]);
        i++;
      }
      const [v] = parseNode(sub, 0, indent + 2);
      out.push(v);
      continue;
    }
    out.push(parseScalar(rest, n));
  }
  return [out, i];
}

function parseMap(lines, i, indent) {
  const out = {};
  while (i < lines.length && lines[i].indent === indent) {
    const { text, n } = lines[i];
    if (text.startsWith('- ')) break;
    const m = KEY_RE.exec(text);
    if (!m) fail(n, `無法解析，預期 \`key: value\`，實際是：${text}`);
    const key = m[1] ?? (m[2] !== undefined ? m[2].replace(/''/g, "'") : m[3].trim());
    const inline = (m[4] ?? '').trim();
    i++;
    if (inline !== '') {
      out[key] = parseScalar(inline, n);
      continue;
    }
    // 值在下一層
    if (i < lines.length && lines[i].indent > indent) {
      const [v, ni] = parseNode(lines, i, lines[i].indent);
      out[key] = v;
      i = ni;
    } else {
      out[key] = null;
    }
  }
  return [out, i];
}

export function parseYaml(text) {
  const lines = tokenize(text);
  if (lines.length === 0) return {};
  const base = lines[0].indent;
  if (base !== 0) fail(lines[0].n, '第一行不該有縮排');
  const [value, next] = parseNode(lines, 0, 0);
  if (next < lines.length) {
    fail(lines[next].n, `縮排對不上（預期 ${base}，實際 ${lines[next].indent}）`);
  }
  return value;
}
