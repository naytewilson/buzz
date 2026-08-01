#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -n "$ROOT/bootstrap.sh"
jq -e . "$ROOT/.plugin/plugin.json" >/dev/null

grep -q '^name: anvil-operator$' "$ROOT/personas/anvil-operator.persona.md"
grep -q '^display_name: ANVIL Operator$' "$ROOT/personas/anvil-operator.persona.md"
grep -q '^runtime: opencode$' "$ROOT/personas/anvil-operator.persona.md"

if command -v buzz >/dev/null 2>&1; then
  buzz pack validate "$ROOT" >/dev/null
  buzz pack inspect "$ROOT" >/dev/null
else
  printf 'SKIP: buzz CLI unavailable; pack parser validation not run\n' >&2
fi

printf 'PASS: ANVIL Buzz integration bundle validation\n'
