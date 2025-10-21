#!/usr/bin/env python3
import sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
ENGRAVING = ROOT / 'Engraving'
REG = ENGRAVING / 'rules' / 'REGISTRY.yaml'

def main():
    rules_doc = yaml.safe_load(REG.read_text())
    rules = rules_doc.get('rules', [])
    missing = []
    for r in rules:
        tr = r.get('trace') or []
        if not isinstance(tr, list) or len(tr) == 0:
            missing.append(r['id'])
    if missing:
        print('TRACE CHECK FAILED')
        print('Rules missing trace anchors:')
        for rid in missing:
            print(f'  - {rid}')
        sys.exit(1)
    print('Trace OK — all rules have at least one trace anchor.')

if __name__ == '__main__':
    main()
