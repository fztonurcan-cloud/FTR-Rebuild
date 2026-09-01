import bpy
import json
import os
import re
from pathlib import Path

OUT = Path(os.environ.get('FTR_ANATOMY_OUT', 'tools/anatomy3d/public'))
MODELS = OUT / 'models'
DATA = OUT / 'data'
MODELS.mkdir(parents=True, exist_ok=True)
DATA.mkdir(parents=True, exist_ok=True)

# FTR Akademi deliberately exports focused study layers instead of whole source collections.
# In particular, the nervous layer excludes sense-organ/inner-ear meshes; the vessel layer
# excludes non-vessel organ meshes. This keeps the module aligned with Kas/Sinir/Ligament/Damar
# and avoids bundling unrelated third-party submodels credited under non-commercial terms.
SYSTEMS = [
    ('skeleton', '1: Skeletal system', None, 'skeleton.glb'),
    ('muscle', '4: Muscular system', None, 'muscular.glb'),
    ('vessel', '5: Cardiovascular system', re.compile(r'(arter|vein|vena|aorta|cava|vascular|vessel|capillar|sinus)', re.I), 'cardiovascular.glb'),
    ('nerve', '7: Nervous system & Sense organs', re.compile(r'(nerve|nervus|nervi|plexus|ganglion|spinal cord|cauda equina|ramus|root)', re.I), 'nervous.glb'),
    ('ligament', '3: Joints', re.compile(r'(ligament|retinacul)', re.I), 'ligaments.glb'),
]

def display_name(raw: str) -> str:
    name = raw.replace('_', ' ').strip()
    name = re.sub(r'\.(?:\d{3})$', '', name)
    name = re.sub(r'\.(?:l|r)$', '', name, flags=re.I)
    name = re.sub(r'\s+', ' ', name).strip()
    return name

def norm(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', ' ', name.lower()).strip()

def select_objects(collection_name, name_filter=None):
    coll = bpy.data.collections.get(collection_name)
    if coll is None:
        raise RuntimeError(f'Collection not found: {collection_name}')
    bpy.ops.object.select_all(action='DESELECT')
    selected = []
    skipped_empty = 0
    for obj in coll.all_objects:
        # Some Z-Anatomy collection links resolve as empty entries in Blender 4.x headless mode.
        # They are not anatomical meshes and must not abort the export.
        if obj is None:
            skipped_empty += 1
            continue
        if obj.type != 'MESH':
            continue
        if name_filter and not name_filter.search(obj.name):
            continue
        try:
            obj.hide_set(False)
        except Exception:
            pass
        obj.hide_viewport = False
        obj.hide_render = False
        obj.select_set(True)
        selected.append(obj)
    if skipped_empty:
        print(f'{collection_name}: skipped {skipped_empty} empty object link(s)')
    if not selected:
        raise RuntimeError(f'No mesh objects selected for: {collection_name}')
    bpy.context.view_layer.objects.active = selected[0]
    return selected

def export_glb(path: Path):
    kwargs = dict(
        filepath=str(path),
        export_format='GLB',
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials='EXPORT',
        export_cameras=False,
        export_lights=False,
        export_animations=False,
    )
    try:
        bpy.ops.export_scene.gltf(
            **kwargs,
            export_draco_mesh_compression_enable=True,
            export_draco_mesh_compression_level=6,
            export_draco_position_quantization=14,
            export_draco_normal_quantization=10,
            export_draco_texcoord_quantization=12,
            export_draco_color_quantization=10,
            export_draco_generic_quantization=12,
        )
    except Exception as exc:
        print(f'Draco export unavailable ({exc}); exporting regular GLB')
        bpy.ops.export_scene.gltf(**kwargs)

structures = {'muscle': {}, 'nerve': {}, 'ligament': {}, 'vessel': {}}
report = {'systems': {}, 'policy': {'excluded_unrelated_noncommercial_submodels': True}}
for system, collection, name_filter, filename in SYSTEMS:
    objects = select_objects(collection, name_filter)
    output = MODELS / filename
    print(f'Exporting {system}: {len(objects)} objects -> {output}')
    export_glb(output)
    report['systems'][system] = {
        'collection': collection,
        'mesh_count': len(objects),
        'file': filename,
        'bytes': output.stat().st_size,
    }
    if system in structures:
        for obj in objects:
            if obj is None:
                continue
            label = display_name(obj.name)
            if len(label) < 3:
                continue
            key = norm(label)
            if key and key not in structures[system]:
                structures[system][key] = {'name': label, 'system': system}

biceps_key = norm('Biceps brachii')
structures['muscle'].setdefault(biceps_key, {'name': 'Biceps brachii', 'system': 'muscle'})
structures['muscle'][biceps_key].update({
    'tr': 'İki başlı kol kası',
    'general': 'Biceps brachii, ön kolun supinasyonunda ve dirseğin fleksiyonunda görev alan iki başlı bir kastır.',
    'origin': 'Caput longum: tuberculum supraglenoidale; caput breve: processus coracoideus.',
    'insertion': 'Tuberositas radii ve aponeurosis bicipitalis.',
    'innervation': 'N. musculocutaneus (C5–C6).',
    'function': 'Dirsek fleksiyonu ve ön kol supinasyonunun güçlü kasıdır; omuz fleksiyonuna yardımcı olur.'
})

(DATA / 'structures.json').write_text(json.dumps(structures, ensure_ascii=False, indent=2), encoding='utf-8')
(DATA / 'export-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
