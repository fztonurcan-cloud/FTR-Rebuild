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

# Premium mobile export: every study system is physically isolated. The selected
# system is the only detailed layer loaded; ligament/vessel/nerve screens may add
# the tiny merged skeleton-reference GLB for anatomical context.
SYSTEMS = [
    ('bone', ('1: Skeletal system', 'Skeletal system'), None, 'skeleton.glb', 0.58),
    ('muscle', ('4: Muscular system', 'Muscular system'), None, 'muscular.glb', 0.48),
    ('ligament', ('3: Joints', 'Joints'), re.compile(r'(ligament|retinacul)', re.I), 'ligaments.glb', 0.68),
    ('vessel', ('5: Cardiovascular system', 'Cardiovascular system'), None, 'cardiovascular.glb', 0.52),
    ('nerve', ('6: Nervous system', 'Nervous system'), None, 'nervous.glb', 0.48),
]


def display_name(raw: str) -> str:
    name = raw.replace('_', ' ').strip()
    name = re.sub(r'(?:\.?\d{3})$', '', name)
    name = re.sub(r'\.(?:l|r)$', '', name, flags=re.I)
    name = re.sub(r'\s+', ' ', name).strip()
    return name


def norm(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', ' ', name.lower()).strip()


def safe_object_fields(obj):
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


def resolve_collection(candidates):
    for name in candidates:
        coll = bpy.data.collections.get(name)
        if coll is not None:
            return coll
    needles = [re.sub(r'^\s*\d+\s*:\s*', '', name).lower().strip() for name in candidates]
    for coll in bpy.data.collections:
        lowered = coll.name.lower()
        if any(needle and needle in lowered for needle in needles):
            return coll
    raise RuntimeError(f'Collection not found. Tried: {candidates}')


def collection_objects(collection, name_filter=None):
    selected = []
    skipped_invalid = 0
    try:
        candidates = list(collection.all_objects)
    except Exception:
        candidates = []
        for child in [collection, *list(collection.children_recursive)]:
            try:
                candidates.extend(list(child.objects))
            except Exception:
                continue
    seen = set()
    for obj in candidates:
        fields = safe_object_fields(obj)
        if fields is None:
            skipped_invalid += 1
            continue
        obj_type, obj_name = fields
        if obj.as_pointer() in seen:
            continue
        seen.add(obj.as_pointer())
        if obj_type != 'MESH' or not getattr(getattr(obj, 'data', None), 'polygons', None):
            continue
        if name_filter and not name_filter.search(obj_name):
            continue
        selected.append(obj)
    if skipped_invalid:
        print(f'{collection.name}: skipped {skipped_invalid} invalid object link(s)')
    if not selected:
        raise RuntimeError(f'No mesh objects selected for: {collection.name}')
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


def polygon_count(objects):
    total = 0
    for obj in objects:
        try:
            total += len(obj.data.polygons)
        except Exception:
            pass
    return total


def add_mobile_decimate(obj, ratio):
    try:
        polygons = len(obj.data.polygons)
    except Exception:
        return
    if ratio >= 0.99 or polygons < 900:
        return
    modifier = obj.modifiers.new(name='FTR Mobile Decimate', type='DECIMATE')
    modifier.decimate_type = 'COLLAPSE'
    modifier.ratio = max(0.12, min(1.0, float(ratio)))


def export_kwargs(path: Path):
    return dict(
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


def run_gltf_export(path: Path):
    kwargs = export_kwargs(path)
    try:
        bpy.ops.export_scene.gltf(
            **kwargs,
            export_draco_mesh_compression_enable=True,
            export_draco_mesh_compression_level=7,
            export_draco_position_quantization=14,
            export_draco_normal_quantization=10,
            export_draco_texcoord_quantization=12,
            export_draco_color_quantization=10,
            export_draco_generic_quantization=12,
        )
    except Exception as exc:
        print(f'Draco export unavailable ({exc}); exporting regular GLB')
        bpy.ops.export_scene.gltf(**kwargs)


def export_glb(path: Path, objects, decimate_ratio):
    original_scene = bpy.context.window.scene
    export_scene = bpy.data.scenes.new('FTR isolated export')
    export_collection = bpy.data.collections.new('FTR isolated meshes')
    export_scene.collection.children.link(export_collection)
    isolated_objects = []
    for source in objects:
        world_matrix = source.matrix_world.copy()
        duplicate = source.copy()
        duplicate.data = source.data.copy()
        duplicate.parent = None
        duplicate.matrix_world = world_matrix
        duplicate.animation_data_clear()
        duplicate.constraints.clear()
        duplicate.modifiers.clear()
        duplicate.hide_set(False)
        duplicate.hide_viewport = False
        duplicate.hide_render = False
        add_mobile_decimate(duplicate, decimate_ratio)
        export_collection.objects.link(duplicate)
        isolated_objects.append(duplicate)

    expected_names = Counter(obj.name for obj in isolated_objects)
    bpy.context.window.scene = export_scene
    bpy.context.view_layer.update()
    try:
        run_gltf_export(path)
    finally:
        bpy.context.window.scene = original_scene
        bpy.data.scenes.remove(export_scene)
        for duplicate in isolated_objects:
            mesh = duplicate.data
            bpy.data.objects.remove(duplicate, do_unlink=True)
            if mesh and mesh.users == 0:
                bpy.data.meshes.remove(mesh)
        if export_collection.users == 0:
            bpy.data.collections.remove(export_collection)

    actual = Counter(glb_mesh_names(path))
    if sum(actual.values()) < 1:
        raise RuntimeError(f'No exported mesh in {path.name}')
    # Blender may normalize duplicate names during export, therefore validate
    # physical isolation by count rather than exact suffix spelling.
    if sum(actual.values()) != sum(expected_names.values()):
        raise RuntimeError(
            f'GLB isolation failed for {path.name}: expected={sum(expected_names.values())} actual={sum(actual.values())}'
        )
    return sum(actual.values())


def export_reference_skeleton(path: Path, bone_objects):
    original_scene = bpy.context.window.scene
    export_scene = bpy.data.scenes.new('FTR skeleton reference export')
    export_collection = bpy.data.collections.new('FTR skeleton reference')
    export_scene.collection.children.link(export_collection)
    duplicates = []
    for source in bone_objects:
        duplicate = source.copy()
        duplicate.data = source.data.copy()
        duplicate.parent = None
        duplicate.matrix_world = source.matrix_world.copy()
        duplicate.animation_data_clear()
        duplicate.constraints.clear()
        duplicate.modifiers.clear()
        duplicate.hide_set(False)
        duplicate.hide_viewport = False
        duplicate.hide_render = False
        export_collection.objects.link(duplicate)
        duplicates.append(duplicate)

    bpy.context.window.scene = export_scene
    bpy.context.view_layer.update()
    try:
        bpy.ops.object.select_all(action='DESELECT')
        for duplicate in duplicates:
            duplicate.select_set(True)
        bpy.context.view_layer.objects.active = duplicates[0]
        bpy.ops.object.join()
        merged = bpy.context.view_layer.objects.active
        merged.name = 'FTR_REFERENCE_SKELETON'
        add_mobile_decimate(merged, 0.16)
        run_gltf_export(path)
    finally:
        bpy.context.window.scene = original_scene
        bpy.data.scenes.remove(export_scene)
        for duplicate in list(duplicates):
            try:
                mesh = duplicate.data
                if duplicate.name in bpy.data.objects:
                    bpy.data.objects.remove(duplicate, do_unlink=True)
                if mesh and mesh.users == 0:
                    bpy.data.meshes.remove(mesh)
            except Exception:
                pass
        if export_collection.users == 0:
            bpy.data.collections.remove(export_collection)

    count = len(glb_mesh_names(path))
    if count != 1:
        raise RuntimeError(f'Reference skeleton must be one mesh, got {count}')
    return count


structures = {key: {} for key, *_ in SYSTEMS}
report = {
    'systems': {},
    'reference': {},
    'policy': {
        'source': 'Z-Anatomy / BodyParts3D',
        'isolated_system_exports': True,
        'mobile_decimation': True,
        'one_detailed_system_loaded_at_a_time': True,
    },
}

resolved = {}
for system, candidates, name_filter, filename, ratio in SYSTEMS:
    collection = resolve_collection(candidates)
    resolved[system] = collection
    objects = collection_objects(collection, name_filter)
    output = MODELS / filename
    before_polygons = polygon_count(objects)
    print(f'Exporting {system}: {len(objects)} objects, {before_polygons} source polygons -> {output}')
    exported_mesh_count = export_glb(output, objects, ratio)
    report['systems'][system] = {
        'collection': collection.name,
        'mesh_count': len(objects),
        'exported_mesh_count': exported_mesh_count,
        'isolated': exported_mesh_count == len(objects),
        'file': filename,
        'bytes': output.stat().st_size,
        'source_polygons': before_polygons,
        'decimate_ratio': ratio,
    }
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

bone_objects = collection_objects(resolved['bone'])
reference_path = MODELS / 'skeleton-reference.glb'
reference_mesh_count = export_reference_skeleton(reference_path, bone_objects)
report['reference'] = {
    'file': reference_path.name,
    'mesh_count': reference_mesh_count,
    'bytes': reference_path.stat().st_size,
    'purpose': 'low-poly anatomical context for ligament/vessel/nerve',
}

(DATA / 'structures.json').write_text(json.dumps(structures, ensure_ascii=False, indent=2), encoding='utf-8')
(DATA / 'export-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
