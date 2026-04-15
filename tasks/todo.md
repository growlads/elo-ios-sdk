# Task Plan

- [x] Inspect the package manifest, tags, and release references to identify the SwiftPM failure.
- [x] Choose the release strategy for a no-users-yet package.
- [in_progress] Align docs and git tag state so `0.0.1` is the real installable release.
- [pending] Verify the repaired tag and document the final publish step.

# Progress Notes

## Root Cause

The published `0.0.1` git tag contains a broken `Package.swift` that references:

- release asset tag `1.0.0`
- a placeholder checksum

Current `main` already points the binary target at release `0.0.1` with a real checksum, so the package source is fixed in the branch but not in the published tag that SwiftPM resolves.

# Strategy

Because there are no downstream users yet, the cleanest fix is to make `0.0.1` the canonical first release by moving that tag to the corrected commit and restoring the docs to reference `0.0.1`.
