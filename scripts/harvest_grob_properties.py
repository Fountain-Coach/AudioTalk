#!/usr/bin/env python3
import sys, re
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'coverage' / 'grob_properties.yaml'

def harvest_properties(lily: Path):
    props = set()
    # Canonical definitions
    canon_files = list(lily.rglob('scm/define-grob-properties.scm'))
    for p in canon_files:
        try:
            txt = p.read_text(errors='ignore')
        except Exception:
            continue
        for m in re.finditer(r"\(\s*([A-Za-z0-9_-]+)\s*,\s*symbol[-A-Za-z0-9_?]+\s+\"", txt):
            props.add(m.group(1))
        for m in re.finditer(r"define-grob-property\s+'([A-Za-z0-9_-]+)\'", txt):
            props.add(m.group(1))
    # Usage-based fallbacks
    for p in lily.rglob('**/*.scm'):
        try:
            txt = p.read_text(errors='ignore')
        except Exception:
            continue
        for m in re.finditer(r"grob-property\s+[^']*'([A-Za-z0-9_-]+)", txt):
            props.add(m.group(1))
        for m in re.finditer(r"ly:grob-property\s+[^']*'([A-Za-z0-9_-]+)", txt):
            props.add(m.group(1))
        for m in re.finditer(r"make-grob-property-override\s+[^']*'([A-Za-z0-9_-]+)", txt):
            props.add(m.group(1))
    norm = sorted({s.replace('-', '_') for s in props})
    return norm

def main():
    if len(sys.argv) < 2:
        print('Usage: harvest_grob_properties.py /path/to/lilypond', file=sys.stderr)
        sys.exit(2)
    lily = Path(sys.argv[1])
    if not lily.exists():
        print(f'Not found: {lily}', file=sys.stderr)
        sys.exit(2)
    props = harvest_properties(lily)
    data = {'properties': props}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(yaml.safe_dump(data, sort_keys=False))
    print(f'Wrote {OUT} with {len(props)} properties.')

if __name__ == '__main__':
    main()
