# AudioTalk (SwiftPM Project)

This repository provides the **source of truth** for the AudioTalk project.

- `VISION.md` — Comprehensive vision statement and design philosophy.
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

See `STATUS-AUDIT.md` for the current ScoreKit audit, prioritized gaps (ties, compound meters, CoreMIDI scheduling), and a hook‑in plan for tomorrow.
