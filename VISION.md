# AudioTalk: A New Language for Sound

## Vision
**AudioTalk** is the missing layer in today’s music and audio ecosystem.  
It creates a **semantic control plane** that lets musicians, developers, and AI systems “talk about sound” in plain, creative terms — while grounding those words in real, actionable synthesis and notation.

Instead of forcing people to think in MIDI CC numbers, raw DSP parameters, or frozen DAW sliders, AudioTalk enables expressions like:

- *“warmer, slower attack, more hall”*
- *“glassy legato crescendo on bars 1–4”*
- *“shimmer pad, brighter only in the melody notes”*

AudioTalk translates these phrases into:
- **Notation edits** (via LilyPond)  
- **MIDI 2.0 / UMP events** (per-note, high-resolution)  
- **Engine parameter updates** (midi2sampler, Csound, SDLKit, GPU DSP nodes)  

And crucially: the vocabulary can **grow dynamically**. New words, new effects, and new DSP features can be added and immediately spoken.

---

## Why Now
- **MIDI 2.0 is here**: high-resolution, per-note control finally exists.  
- **AI/LLMs are ready**: natural language → structured control is a solved problem if we have a stable schema.  
- **Notation still matters**: LilyPond gives us canonical score symbols that can link to sound.  
- **Creators demand fluidity**: modern musicians expect to sketch ideas in words, not navigate menus.  

AudioTalk unifies these trends into one coherent layer.

---

## Unique Abilities / USPs
1. **Semantic Audio Control**  
   - Speak in natural descriptors (“airy”, “plucked”, “ethereal”) and map them to precise notation, UMP, or DSP.
   - Dictionary + Intent API ensures terms are discoverable, extensible, and versioned.

2. **Dynamic Vocabulary Growth**  
   - `/macros` endpoint turns new words into first-class citizens.
   - Ear-training lessons help humans and AIs align language with perception.

3. **Notation ↔ Performance Bridge**  
   - LilyPond as the “truth” of score.
   - Automatic translation of crescendos, staccato, slurs into UMP + engine actions.
   - Performance hints embedded as LilyPond comments (`%!AudioTalk:`) carry timbral intent.

4. **UMP-First MIDI Integration**  
   - Universal MIDI Packets (MIDI 2.0) are the backbone.
   - Per-note expression (PNX), profiles, property exchange, and JR Timestamps all supported.

5. **Multi-Engine Federation**  
   - Works across **midi2sampler** (sample packs, zones, crossfades),  
     **Csound** (advanced synthesis, DSP),  
     **SDLKit** (GPU-powered DSP backend),  
     **LilyPond** (notation engraving).  

6. **Educational Layer**  
   - A/B audio lessons with score snippets train ears to recognize sonic differences.
   - Dictionary explorer shows tokens, meanings, ranges, and example audio.

---

## How It Feels (Look & Experience)
- **For musicians**:  
  Open a score in your browser. Type “legato crescendo, warmer timbre.” The score redraws with slurs and hairpins; the playback updates with filtered resonance and longer envelopes.  
  An A/B lesson pops up: “Which phrase is brighter?” — you click, listen, and learn.

- **For developers**:  
  Call `POST /audiotalk/v1/intent` with `"ethereal pad"`. Get back a JSON plan that touches LilyPond, UMP, and engine channels in one coherent bundle. Dry-run first, apply second. Everything versioned.

- **For LLMs**:  
  AudioTalk is the perfect structured “translation layer.” Free text in → JSON plan out → orchestrate across engines. It becomes trivial for an LLM to act like a sound designer.

---

## Example Workflow
1. **Upload score** (`PUT /notation/score`)  
2. **Speak intent**:  
   ```json
   { "phrase": "warm legato crescendo shimmer", "scope": "bars:1-4" }
   ```  
3. **AudioTalk returns plan**:  
   - Add slur + crescendo in LilyPond  
   - Per-note brightness PNX in UMP  
   - Engine channel updates: cutoff_hz=1800, shimmer_amt=0.6  
4. **Apply plan**: re-render PDF + MIDI + Audio.  
5. **Preview A/B**: listen to before/after, confirm difference.

---

## Roadmap
- **Sprint 1**:  
  - Dictionary & Intent (rule-based)  
  - LilyPond render + apply ops  
  - UMP WS endpoint  
- **Sprint 2**:  
  - Transactional /intent/apply  
  - Macros CRUD & promotion  
  - A/B lessons  
- **Sprint 3**:  
  - Expand engine vocab with GPU DSP (shimmer, convolution)  
  - AI-assisted free-text → macro proposals  
- **Sprint 4**:  
  - Community vocabulary sharing (export/import macros)  
  - Visualization tools (dictionary explorer UI, ear-training UI)

---

## AudioTalk in Context
Think of AudioTalk as the **semantic bus** for sound:  
- DAWs froze vocab into UI panels.  
- Plugins hid DSP under knobs.  
- AudioTalk makes language itself the API.  

For the first time, **notation, sound synthesis, sampling, and creative audio language converge into one open, extensible system**.

---

**Tagline:**  
> *AudioTalk — speak music, hear it happen.*
