const fs = require('fs');
const path = require('path');

const appRoot = path.resolve(__dirname, '..', 'nhamhealth_app');
const translationsRoot = path.join(appRoot, 'lib', 'app', 'translations');

function walk(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const target = path.join(directory, entry.name);
    return entry.isDirectory() ? walk(target) : [target];
  });
}

function catalogue(locale) {
  const keys = [];
  for (const file of walk(path.join(translationsRoot, locale)).filter((item) => item.endsWith('.dart'))) {
    const source = fs.readFileSync(file, 'utf8');
    for (const match of source.matchAll(/^\s*'([^']+)'\s*:/gm)) {
      keys.push({ key: match[1], file });
    }
  }
  return keys;
}

const english = catalogue('en');
const khmer = catalogue('km');
const enKeys = new Set(english.map((item) => item.key));
const kmKeys = new Set(khmer.map((item) => item.key));
const problems = [];

for (const { key, file } of [...english, ...khmer]) {
  if (!/^[a-z]+\.[a-z0-9_]+$/.test(key)) problems.push(`Non-semantic key ${key} in ${file}`);
}
for (const key of enKeys) if (!kmKeys.has(key)) problems.push(`Missing Khmer key: ${key}`);
for (const key of kmKeys) if (!enKeys.has(key)) problems.push(`Missing English key: ${key}`);

for (const [locale, entries] of [['English', english], ['Khmer', khmer]]) {
  const seen = new Set();
  for (const { key } of entries) {
    if (seen.has(key)) problems.push(`Duplicate ${locale} key: ${key}`);
    seen.add(key);
  }
}

for (const file of walk(path.join(appRoot, 'lib')).filter((item) => item.endsWith('.dart'))) {
  if (file.startsWith(translationsRoot)) continue;
  const source = fs.readFileSync(file, 'utf8');
  const literalTranslation = /(['"])((?:\\.|(?!\1).)*)\1\s*\.tr(?:\b|Params\b|Plural\b)/gs;
  for (const match of source.matchAll(literalTranslation)) {
    const key = match[2];
    if (!/^[a-z]+\.[a-z0-9_]+$/.test(key)) {
      const line = source.slice(0, match.index).split(/\r?\n/).length;
      problems.push(`Visible text used as key in ${file}:${line}: ${key.replaceAll('\n', '\\n')}`);
    } else if (!enKeys.has(key)) {
      const line = source.slice(0, match.index).split(/\r?\n/).length;
      problems.push(`Missing catalogue key in ${file}:${line}: ${key}`);
    }
  }

  const safeDynamicTranslation = /(['"])([a-z]+\.[a-z0-9_]+)\1\s*\.trOrSelf\b/g;
  for (const match of source.matchAll(safeDynamicTranslation)) {
    if (!enKeys.has(match[2])) {
      const line = source.slice(0, match.index).split(/\r?\n/).length;
      problems.push(`Missing dynamic catalogue key in ${file}:${line}: ${match[2]}`);
    }
  }
}

console.log(`English keys: ${enKeys.size}`);
console.log(`Khmer keys: ${kmKeys.size}`);
if (problems.length > 0) {
  console.error(problems.join('\n'));
  process.exitCode = 1;
} else {
  console.log('Semantic key, parity, and duplicate checks passed.');
}
