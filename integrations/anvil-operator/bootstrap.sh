#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$SCRIPT_DIR"
PERSONA_FILE="$PACK_DIR/personas/anvil-operator.persona.md"
CANVAS_FILE="$PACK_DIR/canvas.md"

ANVIL_REPO="${ANVIL_REPO:-/Users/Nayte/ANVIL}"
BUZZ_NEST="${BUZZ_NEST:-$HOME/.buzz}"
ANVIL_LINK="$BUZZ_NEST/repos/ANVIL"
CHANNEL_NAME="${BUZZ_ANVIL_CHANNEL:-anvil-control-room}"
AGENT_NAME="${BUZZ_ANVIL_AGENT_NAME:-ANVIL Operator}"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_command buzz
require_command opencode
require_command jq
require_command git

[[ -n "${BUZZ_PRIVATE_KEY:-}" ]] || fail "BUZZ_PRIVATE_KEY is not set in this shell"
: "${BUZZ_RELAY_URL:=http://localhost:3000}"
export BUZZ_RELAY_URL

[[ -d "$ANVIL_REPO/.git" || -f "$ANVIL_REPO/.git" ]] || fail "ANVIL repository not found at $ANVIL_REPO"
for required in \
  governance/CONSTITUTION.md \
  governance/constitution.yaml \
  AGENTS.md \
  COMMAND_CENTER.md \
  cloud_completion_manifest.json; do
  [[ -f "$ANVIL_REPO/$required" ]] || fail "ANVIL source-truth file missing: $ANVIL_REPO/$required"
done

git -C "$ANVIL_REPO" rev-parse --show-toplevel >/dev/null
git -C "$ANVIL_REPO" status --short --branch

mkdir -p "$BUZZ_NEST/repos"
if [[ -L "$ANVIL_LINK" ]]; then
  current_target="$(readlink "$ANVIL_LINK")"
  [[ "$current_target" == "$ANVIL_REPO" ]] || fail "$ANVIL_LINK points to $current_target, not $ANVIL_REPO"
elif [[ -e "$ANVIL_LINK" ]]; then
  fail "$ANVIL_LINK already exists and is not a symlink; refusing to replace it"
else
  ln -s "$ANVIL_REPO" "$ANVIL_LINK"
fi

buzz pack validate "$PACK_DIR" >/dev/null
buzz pack inspect "$PACK_DIR" >/dev/null
buzz users get >/dev/null

channels_json="$(buzz channels search --query "$CHANNEL_NAME" --exact --include-archived)"
channel_count="$(printf '%s' "$channels_json" | jq 'length')"

case "$channel_count" in
  0)
    create_json="$(buzz channels create \
      --name "$CHANNEL_NAME" \
      --type stream \
      --visibility private \
      --description "ANVIL source-truth, execution, receipt, and handoff room")"
    channel_id="$(printf '%s' "$create_json" | jq -r '.channel_id // empty')"
    [[ -n "$channel_id" ]] || fail "Buzz created the channel but returned no channel_id"
    ;;
  1)
    channel_id="$(printf '%s' "$channels_json" | jq -r '.[0].channel_id // empty')"
    archived="$(printf '%s' "$channels_json" | jq -r '.[0].archived // false')"
    [[ -n "$channel_id" ]] || fail "existing channel has no channel_id"
    if [[ "$archived" == "true" ]]; then
      buzz channels unarchive --channel "$channel_id" >/dev/null
    fi
    ;;
  *)
    fail "multiple exact channels named $CHANNEL_NAME exist; resolve the duplicate before continuing"
    ;;
esac

buzz canvas set --channel "$channel_id" --content - < "$CANVAS_FILE" >/dev/null

prompt_file="$(mktemp)"
trap 'rm -f "$prompt_file"' EXIT
awk 'BEGIN { delimiters = 0 } /^---[[:space:]]*$/ { delimiters++; next } delimiters >= 2 { print }' \
  "$PERSONA_FILE" > "$prompt_file"
[[ -s "$prompt_file" ]] || fail "failed to extract persona system prompt"

buzz agents draft-create \
  --channel "$channel_id" \
  --display-name "$AGENT_NAME" \
  --system-prompt - < "$prompt_file" >/dev/null

cat <<EOF2
ANVIL Buzz bootstrap prepared successfully.

Channel: $CHANNEL_NAME
Channel ID: $channel_id
ANVIL link: $ANVIL_LINK -> $ANVIL_REPO

Buzz Desktop should now show a prefilled owner-review form.
Before saving:
  1. Select the OpenCode runtime.
  2. Confirm the name is "$AGENT_NAME".
  3. Keep owner-only response policy.
  4. Save. Buzz will add the new agent to the channel.

Then mention @$AGENT_NAME in the channel. The first turn must remain read-only if ANVIL's required control/claim surface is unavailable.
EOF2
