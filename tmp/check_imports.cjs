const fs = require('fs');
const path = require('path');

const srcDir = path.resolve(process.cwd(), 'react-native-app/src');

function getFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat && stat.isDirectory()) {
      results = results.concat(getFiles(filePath));
    } else if (/\.(tsx|ts|js|jsx)$/.test(file)) {
      results.push(filePath);
    }
  });
  return results;
}

const files = getFiles(srcDir).concat([
  path.resolve(process.cwd(), 'react-native-app/App.tsx'),
  path.resolve(process.cwd(), 'react-native-app/index.js'),
]);

const jsxErrors = [];

files.forEach(filePath => {
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Find all imports
  const imports = {}; // name -> { path, isDefault, origName }
  const importRegex = /import\s+([^"'\n]+?)\s+from\s+['"]([^'"]+)['"]/g;
  let match;
  while ((match = importRegex.exec(content)) !== null) {
    const clause = match[1].trim();
    const impPath = match[2].trim();

    // Default
    const defMatch = clause.replace(/\{[^}]*\}/g, '').replace(/\*\s+as\s+\w+/g, '').trim().replace(/^,|,$/g, '').trim();
    if (defMatch && !defMatch.startsWith('type ')) {
      imports[defMatch] = { path: impPath, isDefault: true };
    }

    // Named
    const namedMatch = clause.match(/\{([^}]+)\}/);
    if (namedMatch) {
      namedMatch[1].split(',').map(s => s.trim()).filter(Boolean).forEach(part => {
        if (part.startsWith('type ')) return;
        const [orig, alias] = part.split(/\s+as\s+/);
        imports[alias || orig] = { path: impPath, isDefault: false, origName: orig };
      });
    }
  }

  // Find all JSX tags <ComponentName
  const jsxTagRegex = /<([A-Z][A-Za-z0-9_]*)/g;
  let tagMatch;
  while ((tagMatch = jsxTagRegex.exec(content)) !== null) {
    const tagName = tagMatch[1];
    if (imports[tagName]) {
      const imp = imports[tagName];
      if (imp.path.startsWith('.')) {
        const dir = path.dirname(filePath);
        let resolved = null;
        const candidates = [
          path.resolve(dir, imp.path),
          path.resolve(dir, imp.path + '.tsx'),
          path.resolve(dir, imp.path + '.ts'),
          path.resolve(dir, imp.path + '.js'),
          path.resolve(dir, imp.path + '/index.tsx'),
          path.resolve(dir, imp.path + '/index.ts'),
          path.resolve(dir, imp.path + '/index.js'),
        ];
        for (const c of candidates) {
          if (fs.existsSync(c) && fs.statSync(c).isFile()) {
            resolved = c;
            break;
          }
        }
        if (!resolved) {
          jsxErrors.push({
            file: path.relative(process.cwd(), filePath),
            component: tagName,
            reason: `Import path ${imp.path} could not be resolved`
          });
        } else {
          const targetContent = fs.readFileSync(resolved, 'utf8');
          if (imp.isDefault) {
            const hasDefault = /export\s+default\b/.test(targetContent);
            if (!hasDefault) {
              jsxErrors.push({
                file: path.relative(process.cwd(), filePath),
                component: tagName,
                reason: `Default import from ${path.relative(process.cwd(), resolved)} but NO export default!`
              });
            }
          } else {
            const searchName = imp.origName || tagName;
            const hasNamed = 
              new RegExp(`export\\s+(?:const|let|var|function|class)\\s+${searchName}\\b`).test(targetContent) ||
              new RegExp(`export\\s*\\{[^}]*\\b${searchName}\\b[^}]*\\}`).test(targetContent) ||
              /export\s*\*\s*from/.test(targetContent);
            if (!hasNamed) {
              jsxErrors.push({
                file: path.relative(process.cwd(), filePath),
                component: tagName,
                reason: `Named export ${searchName} NOT found in ${path.relative(process.cwd(), resolved)}!`
              });
            }
          }
        }
      }
    }
  }
});

console.log('=== JSX COMPONENT ERRORS ===');
console.log(JSON.stringify(jsxErrors, null, 2));
