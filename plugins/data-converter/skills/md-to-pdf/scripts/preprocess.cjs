const fs = require('fs');
const path = require('path');

const srcFile = process.argv[2];
const outMd = process.argv[3];
const imgDir = process.argv[4];

if (!srcFile || !outMd || !imgDir) {
  console.error('Usage: node preprocess.cjs <source.md> <output.md> <imgs-dir>');
  process.exit(1);
}

fs.mkdirSync(imgDir, { recursive: true });
fs.mkdirSync(path.dirname(outMd), { recursive: true });

let content = fs.readFileSync(srcFile, 'utf-8');
const basename = path.basename(srcFile, '.md');
let counter = 0;

content = content.replace(/```mermaid\n([\s\S]*?)```/g, (_match, code) => {
  counter++;
  const id = `mmd-${basename}-${counter}`;
  const mmdFile = path.join(imgDir, `${id}.mmd`);
  fs.writeFileSync(mmdFile, code.trimEnd() + '\n');
  return `![${id}](imgs/${id}.png)`;
});

fs.writeFileSync(outMd, content);
console.log(counter);
