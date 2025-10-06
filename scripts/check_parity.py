#!/usr/bin/env python3
import sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
REG = ROOT / 'rules' / 'REGISTRY.yaml'
COMPONENTS = ROOT / 'coverage' / 'lily_components.yaml'
MAP = ROOT / 'coverage' / 'lily_map.yaml'

def main():
    rules_doc = yaml.safe_load(REG.read_text())
    comp_doc = yaml.safe_load(COMPONENTS.read_text())
    map_doc = yaml.safe_load(MAP.read_text())

    rule_ids = {r['id'] for r in rules_doc.get('rules', [])}
    components = comp_doc.get('components', [])
    mapping = map_doc.get('map', {})

    errors = []
    unmapped = []
    invalid_refs = []

    for comp in components:
        if comp not in mapping:
            unmapped.append(comp)
            continue
        targets = mapping.get(comp) or []
        if len(targets) == 0:
            unmapped.append(comp)
            continue
        for rid in targets:
            if rid not in rule_ids:
                invalid_refs.append((comp, rid))

    if unmapped:
        errors.append(f"Unmapped components: {len(unmapped)}\n  - " + "\n  - ".join(unmapped))
    if invalid_refs:
        lines = [f"Invalid mapping references:"]
        for comp, rid in invalid_refs:
            lines.append(f"  - {comp} -> {rid} (rule not found)")
        errors.append("\n".join(lines))

    if errors:
        print("PARITY CHECK FAILED")
        print("\n\n".join(errors))
        sys.exit(1)
    else:
        print("Parity OK — all Lily components are mapped to declared rules.")

if __name__ == '__main__':
    main()

