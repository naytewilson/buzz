#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -n "$ROOT/bootstrap.sh"
bash -n "$ROOT/prereq-check.sh"
jq -e . "$ROOT/.plugin/plugin.json" >/dev/null

grep -q '^name: anvil-operator$' "$ROOT/personas/anvil-operator.persona.md"
grep -q '^display_name: ANVIL Operator$' "$ROOT/personas/anvil-operator.persona.md"
grep -q '^runtime: opencode$' "$ROOT/personas/anvil-operator.persona.md"
test -f "$ROOT/LIVE_ACCEPTANCE_NEO_2026-08-01.md"
test -x "$ROOT/prereq-check.sh" || test -f "$ROOT/prereq-check.sh"

if command -v buzz >/dev/null 2>&1; then
  buzz pack validate "$ROOT" >/dev/null
  buzz pack inspect "$ROOT" >/dev/null
else
  printf 'SKIP: buzz CLI unavailable; pack parser validation not run\n' >&2
fi

printf 'PASS: ANVIL Buzz integration bundle validation\n'
