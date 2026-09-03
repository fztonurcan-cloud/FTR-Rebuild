import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'public'
MANIFEST_PATH = ROOT / 'data' / 'atlas-map.json'
ID_MAP_PATH = ROOT / 'atlas' / 'muscle-id.png'
LIGAMENT_ID_MAP_PATH = ROOT / 'atlas' / 'ligament-id.png'
LIGAMENT_BEAUTY_PATH = ROOT / 'atlas' / 'ligament-front.png'


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


def high_visibility_ligament_red(data):
    """Tint only ligament pixels red while preserving Workbench shading/depth.

    The skeleton/reference layer stays ivory. The invisible ID map is unchanged,
    so tapping accuracy and structure identity remain exactly the same.
    """
    ligament = data['systems']['ligament']
    structure_rgbs = {tuple(int(channel) for channel in row['rgb']) for row in ligament['structures']}
    if not structure_rgbs:
        raise RuntimeError('Ligament atlas has no structure RGB IDs')

    beauty = Image.open(LIGAMENT_BEAUTY_PATH).convert('RGB')
    ids = Image.open(LIGAMENT_ID_MAP_PATH).convert('RGB')
    if beauty.size != ids.size:
        raise RuntimeError(f'Ligament beauty/ID size mismatch: {beauty.size} vs {ids.size}')

    beauty_pixels = beauty.load()
    id_pixels = ids.load()
    width, height = beauty.size
    changed = 0

    for y in range(height):
        for x in range(width):
            if id_pixels[x, y] not in structure_rgbs:
                continue
            r, g, b = beauty_pixels[x, y]
            # Preserve local lighting/cavity information, but remap the structure
            # into a saturated clinical red that remains obvious on the ivory skeleton.
            luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
            beauty_pixels[x, y] = (
                max(0, min(255, round(178 + 72 * luminance))),
                max(0, min(255, round(22 + 28 * luminance))),
                max(0, min(255, round(30 + 34 * luminance))),
            )
            changed += 1

    if changed < 100:
        raise RuntimeError(f'Ligament high-visibility recolor touched too few pixels: {changed}')

    beauty.save(LIGAMENT_BEAUTY_PATH, optimize=True)
    data.setdefault('policy', {})['ligament_high_visibility_red'] = True
    data['policy']['ligament_skeleton_reference_preserved'] = True
    data['policy']['ligament_id_map_unchanged_by_recolor'] = True
    return changed


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
    ligament_pixels = high_visibility_ligament_red(data)
    MANIFEST_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')

    print(json.dumps({
        'composite': 'Biceps brachii',
        'right': composites['r'],
        'left': composites['l'],
        'recolored_pixels': recolor_counts,
        'muscle_structure_count': len(remaining),
        'ligament_high_visibility_red_pixels': ligament_pixels,
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    run()
