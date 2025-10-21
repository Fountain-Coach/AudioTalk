# AudioTalk Legacy Docs

This folder aggregates legacy documentation slated to be moved to a dedicated repository (proposed: `Fountain-Coach/AudioTalk-LegacyDocs`). It centralizes long-form narratives, audits, and PDFs that informed earlier iterations of AudioTalk and ScoreKit.

Proposed contents to migrate from the top-level of this repo:

- `VISION.md`
- `STATUS-AUDIT.md`
- `ScoreKit.txt`
- `ScoreKit_*.pdf`
- `AudioTalk_*.pdf`
- Any additional narrative documents not required for day-to-day development

Migration steps:

1) Create the repo:
   - Using GitHub: create `AudioTalk-LegacyDocs` under the `Fountain-Coach` org.
2) Populate from this folder and history:
   - Copy files listed above and retain their commit history if you prefer `git subtree split` (optional).
3) Update links:
   - Replace references in this repo’s `README.md` to point to the new repository.

Until the new repository is created, this folder serves as a staging area to keep the monorepo lean while preserving access to the docs.

