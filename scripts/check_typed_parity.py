#!/usr/bin/env python3
import sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
ENGRAVING = ROOT / 'Engraving'
REG = ENGRAVING / 'rules' / 'REGISTRY.yaml'
TYPED = ENGRAVING / 'openapi' / 'rules-as-functions.typed.yaml'

def main():
    reg = yaml.safe_load(REG.read_text())
    typed = yaml.safe_load(TYPED.read_text())
    rules = [r['id'] for r in reg.get('rules', [])]
    paths = typed.get('paths', {})
    ops = [paths[p]['post']['operationId'] for p in paths]
    missing = sorted(set(rules) - set(ops))
    if missing:
        print('TYPED PARITY FAILED')
        print('Typed OpenAPI missing operations for rules:')
        for rid in missing:
            print(f'  - {rid}')
        sys.exit(1)
    print('Typed parity OK — all rules present as typed operations.')

if __name__ == '__main__':
    main()
