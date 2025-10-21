#!/usr/bin/env python3
import sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
ENGRAVING = ROOT / 'Engraving'
UNTYPED = ENGRAVING / 'openapi' / 'rules-as-functions.yaml'
TYPED = ENGRAVING / 'openapi' / 'rules-as-functions.typed.yaml'

def ensure_components(doc):
    comp = doc.setdefault('components', {}).setdefault('schemas', {})
    # Minimal generic typed placeholders; to be refined per rule.
    comp.setdefault('RuleInput', { 'type': 'object', 'additionalProperties': False, 'properties': {} })
    comp.setdefault('RuleOutput', { 'type': 'object', 'additionalProperties': False, 'properties': {} })

def main():
    untyped = yaml.safe_load(UNTYPED.read_text())
    typed = yaml.safe_load(TYPED.read_text())
    ensure_components(typed)
    tpaths = typed.setdefault('paths', {})
    upaths = untyped.get('paths', {})
    for path, op in upaths.items():
        rid = op['post']['operationId']
        if path not in tpaths:
            tpaths[path] = {'post': {
                'operationId': rid,
                'summary': op['post'].get('summary',''),
                'requestBody': {'required': True, 'content': {'application/json': {'schema': {'$ref': '#/components/schemas/RuleInput'}}}},
                'responses': {'200': {'description': 'OK', 'content': {'application/json': {'schema': {'$ref': '#/components/schemas/RuleOutput'}}}}}
            }}
    TYPED.write_text(yaml.safe_dump(typed, sort_keys=False))
    print('Typed OpenAPI updated with parity for all rules (placeholders for new ops).')

if __name__ == '__main__':
    main()
