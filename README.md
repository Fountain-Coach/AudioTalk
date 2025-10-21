# AudioTalk (SwiftPM Project)

This repository provides the **source of truth** for the AudioTalk project.

- `spec/openapi.yaml` — OpenAPI 3.1 definition of the AudioTalk API (source of truth).
- `.gitignore` — Standard SwiftPM ignore file.

## How to use

1. Clone this repo.
2. Explore the `spec/openapi.yaml` to integrate AudioTalk into your services.
3. Use SwiftNIO or your preferred Swift server framework to implement the API.

## Philosophy

We do **not** ship a stub server here.
AudioTalk defines contracts and vision first. Implementations may vary, but the **API contract** is canonical.

## Status & Next Steps

- See `AGENTS.md` for the updated, project‑wide engineering guide based on the Drift–Pattern–Reflection architecture.
- Legacy narrative docs and PDFs have moved to: https://github.com/Fountain-Coach/AudioTalk-LegacyDocs

## Submodules
This repo nests several focused projects as Git submodules:

- `ScoreKit` — notation model, renderer, Lily interop and playback stubs
- `Engraving` — rule engine specs, coverage, and tests for engraving
- `Teatro` — preview/demo apps and rendering API bridges
- `SDLKit` — MIDI 2.0 + SDL/GPU audio backends
- `FountainKit` — foundational backend/foundation APIs shared across projects

Initialize/update all submodules:

```
git submodule update --init --recursive

Note on dependencies
- Use SwiftPM to consume these projects in your packages/apps (preferred). Submodules are included here for context continuity and parity tooling, not direct source imports. Example:
  - Add dependency: `.package(url: "https://github.com/Fountain-Coach/FountainKit.git", from: "0.1.0")`
  - Use product: `.product(name: "FountainKit", package: "FountainKit")`
```

If you already have the directories checked out, the pointers in `.gitmodules` align them to the corresponding upstream repos.
