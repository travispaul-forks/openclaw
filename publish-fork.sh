#!/usr/bin/env bash
# Publish openclaw as @travispaul-forks/openclaw.
# Temporarily renames the package, publishes, then restores the name.
set -euo pipefail

cd "$(dirname "$0")"

# Swap name for publishing
node -e '
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf-8"));
pkg.name = "@travispaul-forks/openclaw";
pkg.publishConfig = { access: "public" };
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
'

echo "Publishing as @travispaul-forks/openclaw..."
npm publish --access public "$@" --tag dev

# Restore original name
node -e '
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf-8"));
pkg.name = "openclaw";
delete pkg.publishConfig;
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
'

echo "Restored package.json name to openclaw"
