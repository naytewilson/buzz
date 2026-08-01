# Buzz + ANVIL Operator Setup

This integration gives ANVIL a visible Buzz control room and a Buzz-managed OpenCode ACP operator without merging Buzz's state model into ANVIL.

## What the bootstrap does

- verifies the real ANVIL checkout and its source-truth files;
- exposes it to Buzz as `~/.buzz/repos/ANVIL` using a symlink;
- validates this persona pack with the installed Buzz CLI;
- reuses or creates a private `anvil-control-room` channel;
- installs the ANVIL authority canvas;
- opens a prefilled, owner-reviewed agent creation form in Buzz Desktop;
- never writes credentials to disk and never writes ANVIL canonical Postgres directly.

## Prerequisites

- Buzz Desktop connected to the intended relay;
- `buzz`, `opencode`, `git`, and `jq` on `PATH`;
- `BUZZ_PRIVATE_KEY` exported for the owner identity;
- `BUZZ_RELAY_URL` exported when the relay is not `http://localhost:3000`;
- the canonical ANVIL checkout at `/Users/Nayte/ANVIL`, or `ANVIL_REPO` set to its verified location.

## Run

From this directory:

```bash
export BUZZ_PRIVATE_KEY='nsec1...'
export BUZZ_RELAY_URL='http://localhost:3000'
bash ./bootstrap.sh
```

Do not commit or paste the private key. The script reads it only from the current process environment.

Buzz Desktop opens the required owner-review form. Select **OpenCode**, retain **owner-only**, and save. The new agent is added to the ANVIL channel automatically.

## Validate without changing a relay

```bash
bash -n bootstrap.sh
jq -e . .plugin/plugin.json >/dev/null
bash ./test.sh
buzz pack validate .
buzz pack inspect .
```

## Authority model

Buzz is the collaboration and visibility layer. ANVIL remains canonical for package claims, leases, worktrees, dispatch, verification, receipts, handoffs, and integration. The Dell remains compute-only.
