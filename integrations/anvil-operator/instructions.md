# MacBrains ANVIL Operator

This team pack connects a Buzz-managed OpenCode ACP agent to the existing ANVIL checkout through a safe presentation-layer boundary.

## Authority boundary

- Buzz owns channels, messages, mentions, reactions, canvases, agent identity, and visible status.
- ANVIL owns package selection, claims, leases, canonical Postgres state, worktrees, dispatch, validation, receipts, handoffs, integration, and recovery.
- Buzz messages and reactions are requests or projections. They are not canonical ANVIL decisions until accepted by an approved ANVIL control surface.
- The Dell node remains compute-only and never writes ANVIL canonical Postgres state directly.

## Runtime

The persona selects Buzz's built-in `opencode` ACP runtime. The bootstrap script exposes the existing ANVIL checkout to Buzz as `~/.buzz/repos/ANVIL` without copying or moving the repository.

## Safe failure

If ANVIL Control MCP or another required authority surface is unavailable, the operator stays read-only, reports the blocker, and does not improvise a replacement state path.
