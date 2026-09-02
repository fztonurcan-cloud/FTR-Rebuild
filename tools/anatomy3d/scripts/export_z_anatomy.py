import bpy
from collections import Counter
import json
import os
import re
import struct
from pathlib import Path

OUT = Path(os.environ.get('FTR_ANATOMY_OUT', 'tools/anatomy3d/public'))
MODELS = OUT / 'models'
DATA = OUT / 'data'
MODELS.mkdir(parents=True, exist_ok=True)
DATA.mkdir(parents=True, exist_ok=True)

# FTR Akademi deliberately exports focused study layers instead of whole source collections.
# The vessel layer excludes non-vessel organ meshes and the joint layer keeps only
# ligament/retinaculum structures. This keeps the simplified module aligned with
# Kas/Ligament/Damar/Kemik and avoids exporting unrelated source collections.
SYSTEMS = [
    ('bone', '1: Skeletal system', None, 'skeleton.glb'),
    ('muscle', '4: Muscular system', None, 'muscular.glb'),
    ('vessel', '5: Cardiovascular system', re.compile(r'(arter|vein|vena|aorta|cava|vascular|vessel|capillar|sinus)', re.I), 'cardiovascular.glb'),
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

def safe_object_fields(obj):
    """Return stable object fields or None for broken/unresolved Blender RNA links."""
    try:
        if obj is None:
            return None
        obj_type = getattr(obj, 'type', None)
        obj_name = getattr(obj, 'name', '')
        if not obj_type:
            return None
        return obj_type, obj_name
    except (AttributeError, ReferenceError, RuntimeError):
        return None

def select_objects(collection_name, name_filter=None):
    coll = bpy.data.collections.get(collection_name)
    if coll is None:
        raise RuntimeError(f'Collection not found: {collection_name}')
    bpy.ops.object.select_all(action='DESELECT')
    selected = []
    skipped_invalid = 0
    # Materialize the collection iteration first; Blender 4 headless can expose stale RNA links.
    try:
        candidates = list(coll.all_objects)
    except Exception:
        candidates = []
        for child in [coll, *list(coll.children_recursive)]:
            try:
                candidates.extend(list(child.objects))
            except Exception:
                continue
    for obj in candidates:
        fields = safe_object_fields(obj)
        if fields is None:
            skipped_invalid += 1
            continue
        obj_type, obj_name = fields
        if obj_type != 'MESH' or not getattr(getattr(obj, 'data', None), 'polygons', None):
            continue
        if name_filter and not name_filter.search(obj_name):
            continue
        try:
            obj.hide_set(False)
            obj.hide_viewport = False
            obj.hide_render = False
            obj.select_set(True)
            selected.append(obj)
        except (AttributeError, ReferenceError, RuntimeError):
            skipped_invalid += 1
            continue
    if skipped_invalid:
        print(f'{collection_name}: skipped {skipped_invalid} invalid object link(s)')
    if not selected:
        raise RuntimeError(f'No mesh objects selected for: {collection_name}')
    try:
        bpy.context.view_layer.objects.active = selected[0]
    except Exception:
        pass
    return selected

def glb_mesh_names(path: Path):
    raw = path.read_bytes()
    if raw[:4] != b'glTF':
        raise RuntimeError(f'Not a GLB file: {path}')
    json_length, json_type = struct.unpack_from('<II', raw, 12)
    if json_type != 0x4E4F534A:
        raise RuntimeError(f'GLB first chunk is not JSON: {path}')
    payload = raw[20:20 + json_length].decode('utf-8').rstrip('\x00 \t\r\n')
    document = json.loads(payload)
    return [node.get('name', '') for node in document.get('nodes', []) if 'mesh' in node]


def export_glb(path: Path, objects):
    # Blender's glTF selection export can retain meshes from sibling collections in
    # this source file. Export from a temporary scene containing only the requested
    # mesh objects so each resulting GLB is physically isolated, not just labelled.
    original_scene = bpy.context.window.scene
    export_scene = bpy.data.scenes.new('FTR isolated export')
    export_collection = bpy.data.collections.new('FTR isolated meshes')
    export_scene.collection.children.link(export_collection)
    for obj in objects:
        export_collection.objects.link(obj)
    bpy.context.window.scene = export_scene
    bpy.context.view_layer.update()

    kwargs = dict(
        filepath=str(path),
        export_format='GLB',
        use_selection=False,
        use_active_scene=True,
        export_apply=True,
        export_yup=True,
        export_materials='EXPORT',
        export_cameras=False,
        export_lights=False,
        export_animations=False,
    )
    try:
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
    finally:
        bpy.context.window.scene = original_scene
        bpy.data.scenes.remove(export_scene)
        bpy.data.collections.remove(export_collection)

    expected = Counter(obj.name for obj in objects)
    actual = Counter(glb_mesh_names(path))
    if actual != expected:
        missing = list((expected - actual).elements())[:20]
        extra = list((actual - expected).elements())[:20]
        raise RuntimeError(
            f'GLB isolation failed for {path.name}: expected={sum(expected.values())} '
            f'actual={sum(actual.values())} missing={missing} extra={extra}'
        )
    return sum(actual.values())

structures = {'muscle': {}, 'ligament': {}, 'vessel': {}, 'bone': {}}
report = {'systems': {}, 'policy': {'excluded_unrelated_noncommercial_submodels': True}}
for system, collection, name_filter, filename in SYSTEMS:
    objects = select_objects(collection, name_filter)
    output = MODELS / filename
    print(f'Exporting {system}: {len(objects)} objects -> {output}')
    exported_mesh_count = export_glb(output, objects)
    report['systems'][system] = {
        'collection': collection,
        'mesh_count': len(objects),
        'exported_mesh_count': exported_mesh_count,
        'isolated': exported_mesh_count == len(objects),
        'file': filename,
        'bytes': output.stat().st_size,
    }
    if system in structures:
        for obj in objects:
            fields = safe_object_fields(obj)
            if fields is None:
                continue
            _, obj_name = fields
            label = display_name(obj_name)
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

fibula_key = norm('Fibula')
structures['bone'].setdefault(fibula_key, {'name': 'Fibula', 'system': 'bone'})
structures['bone'][fibula_key].update({
    'tr': 'Fibula (Kamış kemiği)',
    'general': 'Fibula, bacağın lateralinde yer alan ince uzun kemiktir. Tibia ile birlikte ayak bileği stabilitesine, kas ve ligament tutunmalarına katkı sağlar; vücut ağırlığının yalnız küçük bir bölümünü taşır.',
    'origin': 'Fibularis longus ve brevis, extensor digitorum longus, extensor hallucis longus, flexor hallucis longus, soleus ve tibialis posterior kasları fibulanın farklı yüzlerinden kısmen başlar.',
    'insertion': 'Biceps femoris tendonu fibula başına tutunur. Fibula başı ayrıca lateral kollateral ligament için önemli bir tutunma alanıdır.',
    'innervation': 'Fibula motor innervasyon almaz. Periostu bölgesel duyusal sinir lifleriyle innerve edilir; fibula boynu çevresinde n. fibularis communis yüzeyel seyrettiği için klinik olarak önemlidir.',
    'function': 'Ayak bileğinin lateral stabilitesini destekler, kas ve ligamentler için tutunma yüzeyi sağlar ve alt ekstremite yükünün küçük bir bölümünü iletir.'
})

(DATA / 'structures.json').write_text(json.dumps(structures, ensure_ascii=False, indent=2), encoding='utf-8')
(DATA / 'export-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
