#!/usr/bin/env python3
import sys, re
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
COMP = ROOT / 'coverage' / 'lily_components.yaml'
MAP = ROOT / 'coverage' / 'lily_map.yaml'

KEYMAP = [
  (re.compile(r'beam', re.I), ['RULE.Beaming.subdivision_preference','RULE.Beaming.compound_meter_grouping','RULE.Beaming.auto_knee_threshold','RULE.Beaming.geometry_slope_and_segments','RULE.Beaming.rests_split_groups','RULE.Beaming.suppress_flags_when_beamed']),
  (re.compile(r'slur', re.I), ['RULE.Slur.curvature_choice_with_collision_penalty']),
  (re.compile(r'tie', re.I), ['RULE.Tie.curvature_selection_with_clearance']),
  (re.compile(r'accidental|key', re.I), ['RULE.Accidental.leading_padding_and_column_inflation','RULE.Accidental.key_signature_positions_by_clef','RULE.KeySignature.courtesy_at_line_breaks','RULE.Accidental.cautionary_parenthesized_policy','RULE.Accidental.microtonal_glyph_selection_and_spacing']),
  (re.compile(r'clef', re.I), ['RULE.Clef.mid_system_placement']),
  (re.compile(r'dynamic|hairpin|crescendo', re.I), ['RULE.Dynamics.align_with_noteheads_and_stems']),
  (re.compile(r'lyric', re.I), ['RULE.Lyrics.vertical_alignment_with_baselines']),
  (re.compile(r'ottava', re.I), ['RULE.Ottava.placement_policy']),
  (re.compile(r'volta', re.I), ['RULE.RepeatVolta.layout_policy']),
  (re.compile(r'trill', re.I), ['RULE.TrillSpanner.placement_policy']),
  (re.compile(r'pedal', re.I), ['RULE.Pedal.line_and_text_policy']),
  (re.compile(r'tuplet', re.I), ['RULE.Tuplet.beaming_and_bracket_placement']),
  (re.compile(r'grace', re.I), ['RULE.Grace.clusters_width_policy','RULE.Beaming.subdivision_preference']),
  (re.compile(r'cross.*staff', re.I), ['RULE.CrossStaff.beaming_policy']),
  (re.compile(r'note_?head|rest|spacing', re.I), ['RULE.Spacing.duration_base_with_optical_corrections']),
  (re.compile(r'ledger', re.I), ['RULE.Ledger.shorten_near_accidental']),
  (re.compile(r'staff', re.I), ['RULE.Vertical.min_dist_padding_and_stretch']),
  (re.compile(r'metronome|tempo', re.I), ['RULE.TempoMarks.placement_policy']),
  (re.compile(r'mark_engraver|rehearsal|instrument_name', re.I), ['RULE.RehearsalMarks.placement_policy']),
  (re.compile(r'arpeggio', re.I), ['RULE.Arpeggio.placement_policy']),
  (re.compile(r'fingering', re.I), ['RULE.Fingering.placement_policy']),
  (re.compile(r'script', re.I), ['RULE.Ornaments.placement_above_below_with_collision']),
]

def map_for(name: str):
    lname = name.lower()
    for rx, rules in KEYMAP:
        if rx.search(lname):
            return rules
    return ['RULE.Collision.priority_lattice']

def main():
    comp = yaml.safe_load(COMP.read_text())
    mapping = yaml.safe_load(MAP.read_text())
    m = mapping.setdefault('map', {})
    for c in comp.get('components', []):
        if c.startswith('Engraver.'):
            if c not in m:
                rules = map_for(c)
                m[c] = rules
    MAP.write_text(yaml.safe_dump(mapping, sort_keys=False))
    print('Updated lily_map with Engraver.* mappings (heuristic).')

if __name__ == '__main__':
    main()

