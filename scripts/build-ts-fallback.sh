#!/usr/bin/env bash
# Fallback build script for platforms where tsdown/rolldown is unavailable (e.g. SunOS).
# Replicates tsdown.config.ts output layout using esbuild CLI.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Find esbuild binary in pnpm virtual store
ESBUILD="$(find "$ROOT_DIR/node_modules/.pnpm/esbuild@"*/node_modules/esbuild/bin/esbuild -type f 2>/dev/null | head -1)"
if [[ -z "$ESBUILD" ]]; then
  echo "esbuild binary not found in pnpm store" >&2
  exit 1
fi

COMMON_FLAGS=(
  --bundle
  --platform=node
  --format=esm
  --packages=external
  --define:process.env.NODE_ENV=\"production\"
)

echo "Building with esbuild fallback ($ESBUILD)..."

# tsdown outputs single-entry configs flat (basename only) into outDir.
# Match that by building each single entry with --outfile.
for entry in src/index.ts src/entry.ts src/cli/daemon-cli.ts src/infra/warning-filter.ts src/extensionAPI.ts; do
  basename="$(basename "$entry" .ts).js"
  "$ESBUILD" "$entry" "${COMMON_FLAGS[@]}" --outfile="$ROOT_DIR/dist/$basename"
done

# Plugin SDK entries → dist/plugin-sdk/
mkdir -p "$ROOT_DIR/dist/plugin-sdk"
for entry in src/plugin-sdk/index.ts src/plugin-sdk/account-id.ts; do
  basename="$(basename "$entry" .ts).js"
  "$ESBUILD" "$entry" "${COMMON_FLAGS[@]}" --outfile="$ROOT_DIR/dist/plugin-sdk/$basename"
done

# Hook entries: tsdown groups these with common base src/hooks/ → dist/
# src/hooks/bundled/*/handler.ts → dist/bundled/*/handler.js
# src/hooks/llm-slug-generator.ts → dist/llm-slug-generator.js
HOOK_ENTRIES=()
for f in src/hooks/bundled/*/handler.ts; do
  [[ -f "$f" ]] && HOOK_ENTRIES+=("$f")
done
[[ -f src/hooks/llm-slug-generator.ts ]] && HOOK_ENTRIES+=("src/hooks/llm-slug-generator.ts")

if [[ ${#HOOK_ENTRIES[@]} -gt 0 ]]; then
  "$ESBUILD" \
    "${HOOK_ENTRIES[@]}" \
    "${COMMON_FLAGS[@]}" \
    --outbase=src/hooks --outdir="$ROOT_DIR/dist"
fi

echo "Build complete (esbuild fallback)."
