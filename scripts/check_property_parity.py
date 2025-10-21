#!/usr/bin/env python3
import sys, re
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
ENGRAVING = ROOT / 'Engraving'
REG = ENGRAVING / 'rules' / 'REGISTRY.yaml'
PROP = ROOT / 'coverage' / 'grob_properties.yaml'
PMAP = ROOT / 'coverage' / 'grob_property_map.yaml'

def main():
    reg = yaml.safe_load(REG.read_text())
    props_doc = yaml.safe_load(PROP.read_text())
    pmap = yaml.safe_load(PMAP.read_text())
    rules = {r['id'] for r in reg.get('rules', [])}
    mapping = pmap.get('map', {})
    # Support regex keys: "/pattern/"
    regex_entries = []
    exact_entries = {}
    for k, v in mapping.items():
        if isinstance(k, str) and len(k) >= 2 and k.startswith('/') and k.endswith('/'):
            try:
                rx = re.compile(k[1:-1], re.I)
                regex_entries.append((rx, v))
            except Exception:
                pass
        else:
            exact_entries[k] = v
    missing = []
    invalid = []
    for prop in props_doc.get('properties', []):
        targets = exact_entries.get(prop)
        if targets is None:
            for rx, tv in regex_entries:
                if rx.search(prop):
                    targets = tv
                    break
        if not targets:
            missing.append(prop)
            continue
        for rid in targets:
            if rid not in rules:
                invalid.append((prop, rid))
    if missing or invalid:
        print('PROPERTY PARITY FAILED')
        if missing:
            print('Unmapped properties:', len(missing))
            for p in missing[:50]:
                print(f'  - {p}')
            if len(missing) > 50:
                print(f'  ... and {len(missing)-50} more')
        if invalid:
            print('Invalid rule references:')
            for p, rid in invalid:
                print(f'  - {p} -> {rid}')
        sys.exit(1)
    print('Property parity OK — all grob properties map to declared rules.')

if __name__ == '__main__':
    main()
