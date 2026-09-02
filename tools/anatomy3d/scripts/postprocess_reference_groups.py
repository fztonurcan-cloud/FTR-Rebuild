import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'public'
MANIFEST_PATH = ROOT / 'data' / 'atlas-map.json'
ID_MAP_PATH = ROOT / 'atlas' / 'muscle-id.png'


def is_biceps_head(row):
    return bool(re.search(r'(?:long|short)\s+head\s+of\s+biceps\s+brachii', row.get('name', ''), re.I))


def side_of(row):
    raw = str(row.get('raw', '')).lower()
    if raw.endswith('.r'):
        return 'r'
    if raw.endswith('.l'):
        return 'l'
    return None


def average_anchor(rows):
    anchors = [row.get('anchor') for row in rows if isinstance(row.get('anchor'), list) and len(row['anchor']) == 2]
    if not anchors:
        return [0.5, 0.5]
    return [
        round(sum(float(a[0]) for a in anchors) / len(anchors), 5),
        round(sum(float(a[1]) for a in anchors) / len(anchors), 5),
    ]


def composite_row(rows, side):
    rows = sorted(rows, key=lambda row: int(row['id']))
    primary = rows[0]
    return {
        'id': int(primary['id']),
        'rgb': list(primary['rgb']),
        'name': 'Biceps brachii',
        'raw': f'Biceps brachii.{side}',
        'key': 'biceps brachii',
        'object_type': 'COMPOSITE',
        'anchor': average_anchor(rows),
        'members': [row['raw'] for row in rows],
    }


def recolor_id_map(groups, composites):
    image = Image.open(ID_MAP_PATH).convert('RGB')
    pixels = image.load()
    width, height = image.size

    replacements = {}
    for side, rows in groups.items():
        target = tuple(composites[side]['rgb'])
        for row in rows:
            replacements[tuple(row['rgb'])] = target

    counts = {source: 0 for source in replacements}
    for y in range(height):
        for x in range(width):
            current = pixels[x, y]
            replacement = replacements.get(current)
            if replacement is not None:
                counts[current] += 1
                pixels[x, y] = replacement

    missing = [rgb for rgb, count in counts.items() if count == 0]
    if missing:
        raise RuntimeError(f'Biceps ID colors not found in muscle ID map: {missing}')

    image.save(ID_MAP_PATH, optimize=True)
    return {str(rgb): count for rgb, count in counts.items()}


def run():
    data = json.loads(MANIFEST_PATH.read_text(encoding='utf-8'))
    muscle = data['systems']['muscle']
    rows = muscle['structures']

    groups = {'r': [], 'l': []}
    for row in rows:
        if not is_biceps_head(row):
            continue
        side = side_of(row)
        if side in groups:
            groups[side].append(row)

    for side in ('r', 'l'):
        names = {row['name'].lower() for row in groups[side]}
        if len(groups[side]) != 2 or not any('long head' in name for name in names) or not any('short head' in name for name in names):
            raise RuntimeError(f'Expected long + short Biceps brachii heads for side {side}; got {groups[side]}')

    composites = {side: composite_row(groups[side], side) for side in ('r', 'l')}
    recolor_counts = recolor_id_map(groups, composites)

    grouped_ids = {int(row['id']) for side in groups for row in groups[side]}
    insert_at = min(index for index, row in enumerate(rows) if int(row['id']) in grouped_ids)
    remaining = [row for row in rows if int(row['id']) not in grouped_ids]

    # Right side is first because the locked Kas reference highlights the arm shown
    # on the left side of the screen (anatomical right). The duplicate left composite
    # remains in the raw system data so direct tapping on either arm still works;
    # the UI dedupe layer intentionally shows one canonical “Biceps brachii” row.
    remaining[insert_at:insert_at] = [composites['r'], composites['l']]
    muscle['structures'] = remaining
    muscle['structure_count'] = len(remaining)
    muscle['reference_composites'] = {
        'Biceps brachii': {
            'canonical_side': 'r',
            'sides': ['r', 'l'],
            'members_per_side': 2,
        }
    }

    data.setdefault('policy', {})['reference_composite_groups'] = True
    data['policy']['biceps_brachii_whole_muscle_selection'] = True
    MANIFEST_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')

    print(json.dumps({
        'composite': 'Biceps brachii',
        'right': composites['r'],
        'left': composites['l'],
        'recolored_pixels': recolor_counts,
        'muscle_structure_count': len(remaining),
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    run()
