+# AGENTS.md — ScoreKit Engineering Guide (Fountain‑Coach / AudioTalk)

This document guides contributors and agents building ScoreKit — the notation and real‑time rendering layer described in “ScoreKit: Unifying Notation and Real‑Time Rendering in Fountain‑Coach”. It operationalizes the vision from AudioTalk and the included PDF into concrete architecture, conventions, and milestones.

## Scope
- Applies to files under these paths when they are created:
  - `Sources/ScoreKit/**`
  - `Sources/ScoreKitUI/**`
  - `Examples/ScoreKit*/**`
  - `Tests/ScoreKit*/**`
- Other areas of the repo are not governed by this file unless explicitly stated.

## Mission
- Unify professional engraving (LilyPond as source of truth) with Swift‑native, real‑time score rendering for interactive coaching, editing, and playback.
- Expose a stable Swift API and data model that AI (FountainAI), storage (Fountain‑Store), and audio (MIDI 2.0 / engines) can consume.

## Non‑Goals (for v0)
- Full DAW replacement, full MEI/MusicXML round‑trip fidelity, complex page layout features (parts, cues, ossia) beyond what is needed for interactive coaching.

---

## Architecture Overview
- Core Data Model: immutable-ish score graph with persistent IDs (document, part, staff, measure, voice, event). Semantic annotations are first‑class.
- Engraving Pipeline: LilyPond wrapper for publication‑quality output (PDF/SVG). LilyPond remains the canonical serialization.
- Real‑Time Renderer: Swift renderer (CoreGraphics/SwiftUI) inspired by Verovio for immediate, incremental redraws and highlight/animation.
- Semantics Layer: AudioTalk tags (`%!AudioTalk: ...`) and structured metadata enabling “speak music, hear it happen”.
- I/O Gateways: Import (LilyPond subset, MusicXML/MEI if available), Export (LilyPond authoritative, SVG/PNG snapshots).
- Integration: FountainAI (intents → ops), Fountain‑Store (versioned persistence/search), MIDI 2.0 engines (UMP per‑note playback), Teatro (UI/storyboards).

Recommended SwiftPM packages:
- `ScoreKit` (model + engraving + import/export)
- `ScoreKitUI` (views, renderer, highlights, cursor, selection)

Target platforms:
- macOS primary. iOS supported with LilyPond disabled at runtime (see License section). Linux for server‑side batch rendering (optional).

---

## Module Layout (planned)
```
Package.swift
Sources/
  ScoreKit/
    Model/
    Semantics/
    Engraving/
    ImportExport/
    Playback/
    Core/
  ScoreKitUI/
    Views/
    Rendering/
    Interaction/
Examples/
  ScoreKitPlayground/
Tests/
  ScoreKitTests/
  ScoreKitUITests/
```

---

## Data Model (Core)
- Identity: Every node has a stable `id` (UUID or ULID). Child IDs encode parent linkage.
- Time: `Position` in measures + beats (rational), duration as rational. Don’t assume 4/4.
- Pitch: spelling‑aware (step, alter, octave) plus convenience MIDI number.
- Collections: `Score → Part → Staff → Measure → Voice → Event`
- Event types: Note, Rest, Chord, Tie, Slur (spanning), Articulation, Dynamics, Hairpin, Tempo, Marker, Annotation.
- Semantics: `SemanticTag(key: String, value: Scalar|Enum|Range)` stored on any node; reserved namespace `AudioTalk.*`.
- Diff/Apply: Pure transforms produce new model instances; patch ops are serializable and composable.

Key Swift API sketches:
```swift
struct ScoreID: Hashable { let raw: UUID }
struct Beat: Equatable { let num: Int; let den: Int }
struct Position: Equatable { let measure: Int; let beat: Beat }

struct Pitch { let step: Step; let alter: Int; let octave: Int }
struct Duration { let num: Int; let den: Int }

struct SemanticTag: Hashable { let key: String; let value: SemanticValue }

protocol ScoreNode { var id: ScoreID { get } var tags: [SemanticTag] { get } }
```

Design constraints:
- Deterministic ordering (stable sort keys) for diff and snapshot tests.
- No hidden global state; all transforms take explicit inputs and return outputs.

---

## Engraving (LilyPond)
- LilyPond is the canonical serialization of notation for archival/printing.
- Implement `LilySession` to manage temp workdirs, `.ly` generation, process exec, stderr capture, and artifacts (PDF/SVG/PNG) collection.
- On macOS/Linux: allow runtime LilyPond usage if binary present. On iOS: disable and fallback to native rendering.

CLI constraints:
- Use non‑interactive flags, e.g. `-dno-point-and-click`, output to temp dir, time‑bound process.
- Capture and parse errors to surface precise diagnostics (measure, token) to UI/AI.

Mapping guidelines:
- Model → Lily: ensure idempotent emission; stable formatting to aid diff.
- Semantics → Lily: encode as `%!AudioTalk: key=value` comments co‑located with emitting node.
- Lily → Model: initially subset (notes, durations, ties, slurs, dynamics, hairpins, tempo). Round‑trip where possible; preserve unknown as passthrough comment blocks.

Snapshot policy:
- Golden assets for `.ly` and small PDFs/SVGs under `Tests/Fixtures` with size limits.

---

## Real‑Time Renderer (SwiftUI/CoreGraphics)
- Rendering goals: 60 fps interactions, <16 ms incremental updates for local edits, crisp vector output.
- Layout: incremental engraving per measure/system; cache glyph metrics; reuse layout boxes.
- Drawing: CoreGraphics for glyphs/lines; SwiftUI wrappers for composition; optional SVG export.
- Interaction: hit‑testing, selection, marquee, caret/cursor, region highlight, follow‑playhead.
- Animation: lightweight highlighter for “coaching” changes (fade/flash of affected region); integrates with Teatro storyboard concepts.

Interfaces:
```swift
protocol ScoreRenderable {
  func layout(score: Score, in rect: CGRect, options: LayoutOptions) -> LayoutTree
  func draw(_ tree: LayoutTree, in ctx: CGContext)
  func hitTest(_ tree: LayoutTree, at point: CGPoint) -> ScoreHit?
}
```

---

## Semantics (AudioTalk)
- Namespace: `AudioTalk.*` for standard tags (e.g., `AudioTalk.timbre.brightness`, `AudioTalk.articulation.legato`).
- Attach semantics to any node; scope via ranges (by measure/beat) where needed.
- Provide translation tables to UMP/engine params (see Playback). Keep them versioned.
- Surface semantics both in Lily (comments) and in UI (tooltips/inspector).

---

## Playback / MIDI 2.0
- Output UMP (MIDI 2.0) with per‑note expression aligned to notation.
- JR Timestamps for tight sync with visual playhead.
- Map semantics to engine params for midi2sampler/Csound/SDLKit via a profile table.

---

## Import / Export
- Export: LilyPond (canonical), SVG/PNG snapshots (thumbnails/previews), JSON (model + semantics) for Fountain‑Store.
- Import: LilyPond subset; MusicXML/MEI optional (guarded feature) if parsers available.

---

## Integration Points
- FountainAI: expose high‑level ops (`addSlur`, `applyCrescendo(bars:)`, `annotate(tag:at:)`). Ensure deterministic, explainable diffs.
- Fountain‑Store: persist model JSON + LilyPond + assets; include searchable metadata (keys, ranges, tags).
- Teatro/UI: `ScoreView` SwiftUI component; highlight/animate changes; programmatic selection.

---

## Performance Targets
- Incremental edit to on‑screen update: P50 ≤ 16 ms, P95 ≤ 33 ms.
- Full page layout (A4, moderate density): ≤ 150 ms on M‑class Macs.
- Memory: cache bounded; LRU for glyphs/layout.

Benchmarking:
- Microbenchmarks for layout primitives.
- Scenario tests: insert notes across a measure, add hairpin across 4 bars, toggle articulation across a page.

---

## Testing Strategy
- Unit tests: model transforms, diff/apply, identity preservation, rational arithmetic.
- Property tests: round‑trip Lily subset, idempotency of emit/parse.
- Snapshot tests: Lily `.ly` strings, rendered SVG/PNG (small viewports), layout trees (JSON form).
- Integration tests: LilyPond exec (macOS/Linux CI only) with timeouts and artifact checks.

---

## Tooling & Environment
- Swift 5.9+ / SwiftPM.
- LilyPond (runtime optional, not embedded on iOS). Detect via `PATH`.
- PDFKit (macOS/iOS) for PDF display only; CoreGraphics for drawing.
- Optional: Verovio (LGPL) via C interop or WASM if adopted — gated behind feature flag.

---

## Licensing & Compliance
- LilyPond (GPL) must not be bundled into iOS apps. Access at runtime (user‑installed) or via remote service. macOS command‑line usage is acceptable.
- Keep third‑party code under compatible licenses; isolate via modules and feature flags.

---

## Conventions
- Coding: Swift API design guidelines; value types for model; protocol‑oriented for behaviors.
- Errors: never `fatalError` in library; bubble typed errors with precise context.
- Logging: structured, category‑based, silenced by default in release.
- Doc comments: public APIs documented; examples included.
- Commits: semantic commits (feat:, fix:, perf:, refactor:, docs:, test:, chore:). Reference tickets/issues.
- PRs: small, focused, with before/after screenshots for rendering changes.

---

## Milestones (Guided Delivery)
- M0 Bootstrap: Package scaffolding, core types, fixtures, CI skeleton.
- M1 LilyPond Wrapper: `.ly` emit + CLI exec + error capture + tests.
- M2 Model Transforms: edits (slur, hairpin, articulation), diff/apply, semantics API.
- M3 Renderer MVP: single‑staff layout + notes/rests + ties/slurs + simple dynamics; hit‑testing.
- M4 Semantics→Playback: map tags to UMP profiles; follow playhead.
- M5 Import: Lily subset parser and round‑trip tests.
- M6 UI: `ScoreView` SwiftUI with selection and highlighting; Teatro hooks.
- M7 Performance: caches, incremental layout, benchmarks.
- M8 Docs & Examples: playground app; end‑to‑end demo with AudioTalk intents.

Each milestone should define “Definition of Done” including tests and minimal docs.

---

## Definition of Done (per feature)
- API documented and covered by unit tests.
- Snapshot/golden assets updated with review.
- Performance doesn’t regress against baselines.
- Errors surfaced with actionable messages (measure/beat context).

---

## Agent Tips (for automated contributors)
- Read and respect this AGENTS.md; scope applies only to ScoreKit paths.
- Prefer minimal, surgical changes tied to an issue/milestone.
- When adding new files, follow the Module Layout and Conventions above.
- For LilyPond features, add fixtures and snapshot tests alongside code.
- For renderer changes, attach comparison images in PR descriptions.

---

## References
- “ScoreKit: Unifying Notation and Real‑Time Rendering in Fountain‑Coach” (PDF in repo root)
- `VISION.md` in this repository (AudioTalk vision, semantics)
- LilyPond documentation; MIDI 2.0 UMP specifications; Verovio design notes

