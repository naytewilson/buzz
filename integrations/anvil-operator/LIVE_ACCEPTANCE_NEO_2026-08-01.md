# Live acceptance probe — Neo — 2026-08-01

Agent: CursorCloud  
Task: `anvil-buzz-operator-live-accept`  
Branch: `cursor/anvil-operator-live-prereq-f14e` (onto `integration/anvil-operator-20260801`)  
PR lineage: https://github.com/naytewilson/buzz/pull/1

## Probe commands

```bash
bash ./test.sh
bash ./prereq-check.sh
```

## PROVEN

- `/Users/Nayte/ANVIL` exists and contains the required source-truth files:
  `governance/CONSTITUTION.md`, `governance/constitution.yaml`, `AGENTS.md`,
  `COMMAND_CENTER.md`, `cloud_completion_manifest.json`.
- `opencode` is on PATH at `/Users/nayte/.opencode/bin/opencode`; `OpenCode.app` is installed.
- `bash ./test.sh` PASS (with intentional SKIP when `buzz` is absent).
- `bash -n bootstrap.sh` and `jq -e . .plugin/plugin.json` PASS.
- ANVIL Control MCP remains open/unmerged as `naytewilson/anvil` PR #22.
- FABLE XL admit at probe time: `WAIT` (`swap>=85%`, `P=2 warn`). Cargo build of
  `crates/buzz-cli` was therefore not started.

## MISSING EVIDENCE

- `buzz` binary is not on PATH; no Buzz Desktop app, `~/.buzz`, or BUZZ_* env found on Neo.
- `BUZZ_RELAY_URL` default `http://localhost:3000` is not listening.
- `BUZZ_PRIVATE_KEY` is not available to this agent session (must be entered by the owner
  via silent `read`; never paste into chat, PR, or receipt).
- `buzz pack validate` / `buzz pack inspect` still not run against a real CLI.
- No GitHub CI checks reported on `integration/anvil-operator-20260801`.
- Bootstrap has not created `anvil-control-room`, installed the canvas, or opened the
  owner-reviewed agent form on a live relay.
- No Buzz-thread response from `@ANVIL Operator` proving source-truth preflight behavior.

## POSSIBLY WRONG OR OVERSTATED

- Live relay may not be `http://localhost:3000` once Buzz Desktop is installed.
- A packaged Buzz CLI may exist outside this PATH snapshot.
- OpenCode may still need authentication before Buzz can launch the ACP runtime.

## EXACT NEXT ACTION

On Neo, after Buzz Desktop + CLI are installed and the relay is up:

```bash
cd /path/to/buzz/integrations/anvil-operator
bash ./prereq-check.sh
read -r -s -p 'Buzz owner private key: ' BUZZ_PRIVATE_KEY
printf '\n'
export BUZZ_PRIVATE_KEY
export BUZZ_RELAY_URL='http://localhost:3000'   # or the real relay
bash ./test.sh
bash ./bootstrap.sh
unset BUZZ_PRIVATE_KEY
```

In the Desktop form: Runtime **OpenCode**, Response policy **Owner only**,
Name **ANVIL Operator**, then Save. Mention `@ANVIL Operator` and require a
read-only source-truth preflight report while Control MCP / claim authority is unavailable.

## WHAT DOES NOT COUNT AS COMPLETION

Creating or updating this PR, adding `prereq-check.sh`, opening the agent form, or seeing
the agent listed in a channel does not prove the workflow. Completion requires a Buzz
response that inspects the real ANVIL checkout, emits or attempts canonical source-truth
preflight, and correctly remains read-only when claim authority is unavailable.

## SAFE TO CONTINUE HERE OR START A FRESH CONTEXT

Safe to continue here once Buzz CLI + relay + owner key are available on Neo.
Do not cargo-build Buzz while FABLE XL admit is WAIT.
