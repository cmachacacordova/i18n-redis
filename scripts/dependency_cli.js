const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Path to vcpkg.json relative to this script
const VCPKG_JSON = path.join(__dirname, '..', 'vcpkg.json');

// List of available dependencies for demonstration purposes
const AVAILABLE_DEPS = [
  'nlohmann-json',
  'redis-plus-plus',
  'fmt',
  'spdlog'
];

function loadCurrentDependencies() {
  const data = JSON.parse(fs.readFileSync(VCPKG_JSON, 'utf8'));
  return data.dependencies || [];
}

function saveDependencies(deps) {
  const data = JSON.parse(fs.readFileSync(VCPKG_JSON, 'utf8'));
  data.dependencies = deps;
  fs.writeFileSync(VCPKG_JSON, JSON.stringify(data, null, 2));
  console.log('Dependencies updated in vcpkg.json');
}

function askQuestion(rl, question) {
  return new Promise(resolve => rl.question(question, answer => resolve(answer)));
}

async function main() {
  const current = new Set(loadCurrentDependencies());
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const selected = [];

  for (const dep of AVAILABLE_DEPS) {
    const def = current.has(dep) ? 'Y/n' : 'y/N';
    const answer = await askQuestion(rl, `Include ${dep}? (${def}) `);
    const norm = answer.trim().toLowerCase();
    const yes = norm ? norm.startsWith('y') : current.has(dep);
    if (yes) {
      selected.push(dep);
    }
  }

  rl.close();
  saveDependencies(selected);
}

if (require.main === module) {
  main();
}
