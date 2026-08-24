const fs = require('fs');
const path = require('path');

const roots = process.argv.slice(2);
const uiMarkers = /\b(Text|TextSpan|label|hintText|labelText|helperText|errorText|tooltip|message|title|subtitle|placeholder|semanticLabel|AppAlert|snackbar)\b/;
const ignored = /^(assets\/|package:|\/|[a-z_]+\/[a-z_\/]+|[a-z_]+\.[a-z_]+|#[0-9a-f]+$)/i;

function walk(target) {
  const stat = fs.statSync(target);
  if (stat.isFile()) return target.endsWith('.dart') ? [target] : [];
  return fs.readdirSync(target, {withFileTypes: true}).flatMap((entry) =>
    walk(path.join(target, entry.name)),
  );
}

for (const file of roots.flatMap(walk).sort()) {
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  for (let index = 0; index < lines.length; index += 1) {
    const context = lines.slice(Math.max(0, index - 2), index + 2).join(' ');
    if (!uiMarkers.test(context)) continue;

    const literalPattern = /(['"])([^'"\n]{2,})\1/g;
    for (const match of lines[index].matchAll(literalPattern)) {
      const value = match[2].trim();
      const after = lines[index].slice((match.index ?? 0) + match[0].length);
      if (!/[A-Za-z]/.test(value) || ignored.test(value) || /^\.tr/.test(after)) {
        continue;
      }
      console.log(`${file}:${index + 1}\t${value}`);
    }
  }
}
