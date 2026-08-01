#!/usr/bin/env bash
# Fail-closed live-acceptance probe for the ANVIL Buzz operator bundle.
# Does not read, print, or persist BUZZ_PRIVATE_KEY material.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANVIL_REPO="${ANVIL_REPO:-/Users/Nayte/ANVIL}"
BUZZ_NEST="${BUZZ_NEST:-$HOME/.buzz}"
ANVIL_LINK="$BUZZ_NEST/repos/ANVIL"
RELAY_URL="${BUZZ_RELAY_URL:-http://localhost:3000}"

pass=0
fail=0
skip=0

stamp() {
  printf '%-7s %s\n' "$1" "$2"
}

ok() { stamp PROVEN "$1"; pass=$((pass + 1)); }
bad() { stamp MISSING "$1"; fail=$((fail + 1)); }
soft() { stamp SKIP "$1"; skip=$((skip + 1)); }

require_file() {
  if [[ -f "$1" ]]; then
    ok "file present: $1"
  else
    bad "file missing: $1"
  fi
}

if command -v jq >/dev/null 2>&1; then
  ok "jq on PATH: $(command -v jq)"
else
  bad "jq not on PATH"
fi

if command -v git >/dev/null 2>&1; then
  ok "git on PATH: $(command -v git)"
else
  bad "git not on PATH"
fi

if command -v opencode >/dev/null 2>&1; then
  ok "opencode on PATH: $(command -v opencode)"
else
  bad "opencode not on PATH"
fi

if command -v buzz >/dev/null 2>&1; then
  ok "buzz on PATH: $(command -v buzz)"
  if buzz pack validate "$SCRIPT_DIR" >/dev/null 2>&1; then
    ok "buzz pack validate"
  else
    bad "buzz pack validate failed"
  fi
  if buzz pack inspect "$SCRIPT_DIR" >/dev/null 2>&1; then
    ok "buzz pack inspect"
  else
    bad "buzz pack inspect failed"
  fi
else
  bad "buzz CLI not on PATH (cannot run pack validate/inspect or bootstrap)"
fi

if [[ -n "${BUZZ_PRIVATE_KEY:-}" ]]; then
  ok "BUZZ_PRIVATE_KEY is set in this shell (value not printed)"
else
  bad "BUZZ_PRIVATE_KEY is not set in this shell"
fi

if [[ -d "$ANVIL_REPO/.git" || -f "$ANVIL_REPO/.git" ]]; then
  ok "ANVIL checkout at $ANVIL_REPO"
else
  bad "ANVIL checkout missing at $ANVIL_REPO"
fi

for required in \
  governance/CONSTITUTION.md \
  governance/constitution.yaml \
  AGENTS.md \
  COMMAND_CENTER.md \
  cloud_completion_manifest.json; do
  require_file "$ANVIL_REPO/$required"
done

if [[ -L "$ANVIL_LINK" ]]; then
  target="$(readlink "$ANVIL_LINK")"
  if [[ "$target" == "$ANVIL_REPO" ]]; then
    ok "ANVIL symlink $ANVIL_LINK -> $ANVIL_REPO"
  else
    bad "ANVIL symlink points to $target, expected $ANVIL_REPO"
  fi
elif [[ -e "$ANVIL_LINK" ]]; then
  bad "$ANVIL_LINK exists and is not a symlink; bootstrap will refuse"
else
  soft "ANVIL symlink not created yet (bootstrap will create $ANVIL_LINK)"
fi

relay_host="${RELAY_URL#*://}"
relay_host="${relay_host%%/*}"
if command -v curl >/dev/null 2>&1; then
  if curl -fsS -m 2 "$RELAY_URL" >/dev/null 2>&1 || curl -fsS -m 2 "$RELAY_URL/health" >/dev/null 2>&1; then
    ok "relay reachable at $RELAY_URL"
  else
    bad "relay not reachable at $RELAY_URL (host=$relay_host)"
  fi
else
  soft "curl unavailable; relay reachability not probed"
fi

bash -n "$SCRIPT_DIR/bootstrap.sh"
ok "bash -n bootstrap.sh"
jq -e . "$SCRIPT_DIR/.plugin/plugin.json" >/dev/null
ok "plugin.json parses"
bash "$SCRIPT_DIR/test.sh" >/dev/null
ok "test.sh PASS"

printf '\nSUMMARY pass=%s fail=%s skip=%s\n' "$pass" "$fail" "$skip"
if [[ "$fail" -gt 0 ]]; then
  printf 'RESULT: NOT READY for live bootstrap\n'
  exit 1
fi
printf 'RESULT: READY for live bootstrap (still requires owner-reviewed Desktop save)\n'
exit 0
