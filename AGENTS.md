# AGENTS.md — AudioTalk Project Engineering Guide (Drift–Pattern–Reflection)

This document aligns contributors and agents with the updated AudioTalk vision described in “AudioTalk – The Composition Engine: A Drift–Pattern–Reflection Architecture for Symbolic Music Reasoning” (PDF in the LegacyDocs repository). It replaces the ScoreKit‑only guide with a project‑wide blueprint.

## Scope
- Applies to the AudioTalk monorepo and its submodules:
  - `ScoreKit/` (notation model, renderer, playback glue)
  - `Engraving/` (rules, glyph metrics, coverage, OpenAPI)
  - `Teatro/` (preview apps, renderer/preview APIs)
  - `SDLKit/` (MIDI 2.0 + audio backends)
- For code inside submodules, prefer their local AGENTS.md conventions when present; this guide sets cross‑project expectations and integration rules.

## Mission
- Establish AudioTalk as the semantic control plane for sound and notation, enabling natural language to produce faithful notation, performance, and previews.
- Operationalize the Drift–Pattern–Reflection architecture across repos to ensure the system learns (Drift), is grounded by rules (Pattern), and verifies outcomes (Reflection).

## Non‑Goals (phase‑wise)
- Not a DAW replacement; no full MEI/MusicXML fidelity in v0.
- Avoid heavy desktop editor features; prioritize live preview and explainability.

---

## Architecture
- Drift (Language + Macros)
  - Extensible vocabulary: macros and descriptors; promote via review.
  - Intent parsing produces typed operations spanning engraving + playback.
  - Sources: LLMs, rule‑based intents, user macros; all versioned.
- Pattern (Rules + Authority)
  - Engraving is the canonical authority for layout/engraving rules and glyph metrics.
  - Rules are explicit functions (OpenAPI in `Engraving/openapi/`), traceable and testable.
  - ScoreKit consumes Engraving outputs for grouping, spacing, ties/slurs, accidentals, etc.
- Reflection (Verification + Feedback)
  - Visual snapshots (PNG/SVG), score model diffs, and UMP traces.
  - Benchmarks for latency/jitter, incremental reflow, memory.
  - A/B previews and user confirmation loops for macro promotion.

### System Components
- API Contract: `spec/openapi.yaml` is the public contract for intents and preview orchestration.
- Notation: `ScoreKit/` provides model + real‑time renderer and import/export (Lily interop optional, gated by `ENABLE_LILYPOND`).
- Engraving Rules: `Engraving/` provides rules, coverage maps, and parity tooling.
- Playback: `ScoreKit/Playback` emits UMP; engines live in `SDLKit/` and downstream projects.
- UI/Preview: `Teatro/` provides SwiftUI previews and bridge APIs for live runs and comparisons.

---

## Cross‑Repo Conventions
- Single source of truth
  - Engraving rules → renderer behavior; avoid duplicating heuristics in UI.
  - `spec/openapi.yaml` → service boundaries; keep implementations conformant.
- Determinism
  - Stable ordering, pure transforms for diffs/snapshots.
- Errors
  - No `fatalError` in libraries. Bubble typed errors with precise measure/beat/pitch context.
- Logging
  - Structured, category‑based, quiet in release.
- Commits/PRs
  - Semantic commits. Small PRs with before/after snapshots for visual or audio effects.

---

## Milestones (Project‑level)
- P0 Preview Fidelity
  - Ties (over barlines), compound meter beaming, slanted beams.
  - CoreMIDI JR timestamps and host‑time mapping.
  - Deterministic diffs and fast incremental reflow.
- P1 Multi‑Voice + Semantics→Playback
  - Voice collisions, stems, basic cross‑staff.
  - Articulation timing/length profiles; initial per‑note attributes.
- P2 Live AI Loop
  - WebSocket/IPC preview stream; macro propose→review→promote.
  - A/B snapshots for review; persistence into Fountain‑Store.
- P3 Coverage + Import
  - Lily subset round‑trip; key/time/tempo changes; more dynamics/ornaments.

Each deliverable defines Definition of Done: API doc + tests + snapshots + perf checks.

---

## Testing & Benchmarks
- Unit tests for model transforms and encoders.
- Property tests for round‑trips and idempotency where applicable.
- Renderer snapshots (PNG/SVG); UMP traces for playback.
- Bench in CI: layout/update timings with soft thresholds; JR jitter budget.

---

## Tooling & Environments
- Swift 5.9+ / SwiftPM; macOS primary.
- LilyPond optional at runtime for interop (not bundled on iOS).
- Submodules required; initialize with `git submodule update --init --recursive`.

---

## Documentation Policy
- Current, normative docs stay minimal in this repo: `README.md`, this `AGENTS.md`, `spec/openapi.yaml`.
- All legacy narrative docs, long‑form PDFs, and archival notes move to a new “Legacy Docs” repository.
- Keep per‑repo AGENTS.md in submodules for code‑local guidance; link back to this document for cross‑repo rules.

---

## Principal Task — Cross‑Session Context Continuity

Goal
- Preserve and surface shared project context across sessions and repos so that contributors and agents can continue work seamlessly without re‑discovery.

Deliverables we maintain
- Parity Scoreboard (Engraving): `SCOREBOARD.md` classifies every curated `Engraver.*` family as Done/Partial/Todo, driven by `coverage/lily_components.yaml` + `coverage/lily_map.yaml` + rules `REGISTRY.yaml`.
- Audit Report (Engraving): `AUDIT.md` + CI JSON artifact summarizing rule counts/status, OpenAPI parity, tests, component coverage, and grob property mapping quality.
- CI Artifacts (Monorepo): CI uploads both the Engraving audit and scoreboard artifacts on every run to make state visible beyond a single session.
- Submodule Sync: this repo points submodules to the latest Engraving and ScoreKit commits that keep gates green; ScoreKit README links to Engraving audit/scoreboard.

Operating Model (Expand → Map → Ratify → Sync)
1) Expand curated components from LilyPond sources (via generator),
2) Map new Engraver/Grob families to rules (heuristic first, then explicit properties),
3) Add/ratify rules with typed schemas and tests (update typed lock),
4) Sync submodules and update docs/CI artifacts.

Acceptance Criteria (per iteration)
- Parity green: `check_parity.py` (components↔rules) and `check_property_parity.py` (grob properties) pass.
- OpenAPI parity: untyped/typed in lockstep; typed lint OK; no placeholders for ratified.
- All ratified rules have tests; audit and scoreboard artifacts published.
- ScoreKit docs link to Engraving parity (no stale links).

Maintenance Tasks & Cadence
- Daily/Weekly
  - Refresh Engraving audit and scoreboard in CI; review regression deltas.
  - Convert high‑impact regex property categories to explicit mappings; keep defaults at 0.
  - Bump submodule pointers in AudioTalk after Engraving updates; ensure monorepo CI passes.
- As Needed
  - Expand curated LilyPond components (generator over vendor or upstream trees) and reconcile mappings.
  - Promote provisional rules to ratified with typed schemas and lock updates.
  - Add a second scenario to core tests (QA polish) and keep scenario coverage job green.

Owner Responsibilities
- Engraving maintainers: rules, coverage, OpenAPI, audit/scoreboard, CI gates.
- ScoreKit maintainers: consume rule contracts (RulesKit), keep README parity links fresh, align renderer heuristics with rule outputs.
- Monorepo owners: ensure CI runs audit + scoreboard and uploads artifacts; coordinate submodule bumps.

Risk Controls
- Typed lock enforces ratified schema stability; migrations require explicit notes.
- No default property mappings; regex categories allowed for breadth but continuously narrowed to specifics.
- Audit + scoreboard artifacts ensure context continuity across sessions and contributors.

---

## Next Steps (Migration Plan)
- Create a new repo “AudioTalk‑LegacyDocs” in the Fountain‑Coach org.
- Move top‑level legacy docs into it (see file list in PR):
  - `VISION.md`, `STATUS-AUDIT.md`, `ScoreKit.txt`, `ScoreKit_*.pdf`, `AudioTalk_*.pdf`, and similar narrative assets.
- In this repo:
  - Keep `README.md`, `AGENTS.md`, and `spec/openapi.yaml` minimal and current.
  - Replace moved files with links to the new repo.
- Add CI job at top‑level to assert submodules initialized and run Engraving parity checks.

---

## References
- “AudioTalk – The Composition Engine: Drift–Pattern–Reflection” (PDF)
- `spec/openapi.yaml` — API contract
- `ScoreKit/AGENTS.md` — local renderer/model guidance
- `Engraving/AGENTS.md` — rules/coverage guidance
 - Engraving Audit/Scoreboard: see `Engraving/AUDIT.md` and `Engraving/SCOREBOARD.md`; CI artifacts `engraving-audit` and `engraving-scoreboard`.

---

## Developer Commands (optional)
These commands are for contributors who want to verify parity and generate continuity artifacts locally.

- Initialize submodules
  - `git submodule update --init --recursive`
- Quick parity check (root helper)
  - `./scripts/engraving_parity_check.sh`
- Generate audit + scoreboard (inside Engraving)
  - `cd Engraving && python scripts/audit_rules_coverage.py > AUDIT.json && python scripts/build_scoreboard.py`
  - Outputs: `Engraving/AUDIT.json`, `Engraving/SCOREBOARD.md`
 - Engraving Audit/Scoreboard: see `Engraving/AUDIT.md` and `Engraving/SCOREBOARD.md`; CI artifacts `engraving-audit` and `engraving-scoreboard`.
