import bpy
import json
import os
import re
from collections import Counter
from pathlib import Path
from mathutils import Vector

OUT = Path(os.environ.get('FTR_ANATOMY_OUT', 'tools/anatomy3d/public'))
ATLAS = OUT / 'atlas'
DATA = OUT / 'data'
ATLAS.mkdir(parents=True, exist_ok=True)
DATA.mkdir(parents=True, exist_ok=True)

WIDTH = int(os.environ.get('FTR_ATLAS_WIDTH', '720'))
HEIGHT = int(os.environ.get('FTR_ATLAS_HEIGHT', '1120'))
ASPECT = WIDTH / HEIGHT

SYSTEMS = [
    ('muscle', ('4: Muscular system', 'Muscular system'), None, ('MESH',)),
    ('bone', ('1: Skeletal system', 'Skeletal system'), None, ('MESH',)),
    ('ligament', ('3: Joints', 'Joints'), re.compile(r'(ligament|retinacul)', re.I), ('MESH',)),
    # Z-Anatomy stores most peripheral vessels and nerves as CURVE objects.
    ('vessel', ('5: Cardiovascular system', 'Cardiovascular system'), None, ('MESH', 'CURVE')),
    ('nerve', ('6: Nervous system', 'Nervous system'), None, ('MESH', 'CURVE')),
]
REFERENCE_SYSTEMS = {'ligament', 'vessel', 'nerve'}
BONE_CANDIDATES = ('1: Skeletal system', 'Skeletal system')

# Non-muscular connective/synovial layers were visually covering the muscle atlas.
# Keep true tendons and the muscle Tensor fasciae latae, but remove fascia sheets,
# bursae, tendon sheaths, retinacula, septa, aponeuroses and ligaments from the
# *muscle presentation*. Those structures remain available in their own systems.
MUSCLE_PRESENTATION_EXCLUDE = re.compile(
    r'(?:\bburs(?:a|ae)\b|\bsheaths?\b|\bretinaculum\b|\bligament\b|'
    r'\bintermuscular\s+septum\b|\baponeurosis\b|\bfascia\b)',
    re.I,
)
SYSTEM_TEXT_ARTIFACT = re.compile(r'\bsystem(?:\.g)?$', re.I)

# Exact preferred objects are placed before branch/child structures. main.js uses
# the first regex match as its initial selection, so this guarantees that opening
# Sinirler selects the whole Median nerve rather than a small digital branch.
PREFERRED_EXACT = {
    'bone': {'fibula'},
    'ligament': {'anterior talofibular ligament'},
    'vessel': {'anterior tibial artery'},
    'nerve': {'median nerve', 'n medianus'},
}


def display_name(raw: str) -> str:
    name = raw.replace('_', ' ').strip()
    name = re.sub(r'(?:\.?\d{3})$', '', name)
    name = re.sub(r'\.(?:l|r)$', '', name, flags=re.I)
    name = re.sub(r'\s+', ' ', name).strip()
    return name


def norm(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', ' ', name.lower()).strip()


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


def has_renderable_geometry(obj):
    try:
        if obj.type == 'MESH':
            return bool(obj.data and len(obj.data.polygons) > 0)
        if obj.type == 'CURVE':
            return bool(obj.data and len(obj.data.splines) > 0)
    except Exception:
        return False
    return False


def is_presentation_artifact(system, obj):
    label = display_name(obj.name)
    if SYSTEM_TEXT_ARTIFACT.search(label):
        return True
    if system == 'muscle' and MUSCLE_PRESENTATION_EXCLUDE.search(label):
        return True
    return False


def collection_objects(
    collection,
    system,
    name_filter=None,
    allowed_types=('MESH',),
    exclude_keys=None,
):
    try:
        candidates = list(collection.all_objects)
    except Exception:
        candidates = []
        for child in [collection, *list(collection.children_recursive)]:
            try:
                candidates.extend(list(child.objects))
            except Exception:
                pass

    allowed_types = set(allowed_types)
    exclude_keys = exclude_keys or set()
    rows = []
    seen = set()
    skipped_context = 0
    skipped_presentation = 0

    for obj in candidates:
        try:
            ptr = obj.as_pointer()
            if ptr in seen:
                continue
            seen.add(ptr)
            if obj.type not in allowed_types or not has_renderable_geometry(obj):
                continue
            if name_filter and not name_filter.search(obj.name):
                continue
            if is_presentation_artifact(system, obj):
                skipped_presentation += 1
                continue
            key = norm(display_name(obj.name))
            if key and key in exclude_keys:
                skipped_context += 1
                continue
            rows.append(obj)
        except Exception:
            continue

    if not rows:
        raise RuntimeError(
            f'No renderable objects for {collection.name} / system={system} / types={sorted(allowed_types)}'
        )

    preferred = PREFERRED_EXACT.get(system, set())
    if preferred:
        # Stable sort: exact preferred structures first, source order otherwise.
        rows.sort(key=lambda obj: 0 if norm(display_name(obj.name)) in preferred else 1)

    counts = Counter(obj.type for obj in rows)
    print(
        f'[STATIC ATLAS] {collection.name}: selected types={dict(counts)} '
        f'excluded_context={skipped_context} excluded_presentation={skipped_presentation}'
    )
    return rows


def bbox_world(objects):
    pts = []
    for obj in objects:
        try:
            for corner in obj.bound_box:
                pts.append(obj.matrix_world @ Vector(corner))
        except Exception:
            pass
    if not pts:
        raise RuntimeError('No bounding box points')
    min_v = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    max_v = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return min_v, max_v


def object_center(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return sum(points, Vector()) / len(points)


def beauty_rgba(system, raw_name):
    n = raw_name.lower()
    if system == 'muscle':
        if re.search(r'tendon', n):
            return (0.90, 0.82, 0.69, 1.0)
        return (0.72, 0.11, 0.055, 1.0)
    if system == 'bone':
        return (0.90, 0.84, 0.72, 1.0)
    if system == 'ligament':
        return (0.92, 0.89, 0.80, 1.0)
    if system == 'vessel':
        if re.search(r'vein|vena|venous|saphen|sinus', n):
            return (0.045, 0.20, 0.84, 1.0)
        return (0.88, 0.035, 0.055, 1.0)
    if system == 'nerve':
        if re.search(r'brain|cerebr|spinal cord|medulla|pons|thalam|cortex|gyrus|sulcus', n):
            return (0.66, 0.47, 0.28, 1.0)
        return (1.00, 0.64, 0.02, 1.0)
    return (0.72, 0.72, 0.72, 1.0)


def id_rgb(index):
    """4096 well-separated non-black IDs; robust against edge antialiasing."""
    value = int(index)
    return [
        (value & 15) * 16 + 8,
        ((value >> 4) & 15) * 16 + 8,
        ((value >> 8) & 15) * 16 + 8,
    ]


def id_rgba(index):
    rgb = id_rgb(index)
    return tuple(channel / 255.0 for channel in rgb) + (1.0,)


def set_if(obj, name, value):
    if not hasattr(obj, name):
        return
    try:
        setattr(obj, name, value)
    except Exception:
        pass


def setup_scene(name, id_pass=False):
    scene = bpy.data.scenes.new(name)
    coll = bpy.data.collections.new(name + ' objects')
    scene.collection.children.link(coll)

    try:
        scene.render.engine = 'BLENDER_WORKBENCH'
    except Exception:
        scene.render.engine = 'BLENDER_WORKBENCH_NEXT'

    scene.render.resolution_x = WIDTH
    scene.render.resolution_y = HEIGHT
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB' if id_pass else 'RGBA'
    scene.render.image_settings.color_depth = '8'
    scene.render.film_transparent = False

    shading = scene.display.shading
    set_if(shading, 'color_type', 'OBJECT')
    set_if(shading, 'background_type', 'VIEWPORT')
    set_if(shading, 'show_outline', False)

    if id_pass:
        set_if(shading, 'light', 'FLAT')
        set_if(shading, 'show_shadows', False)
        set_if(shading, 'show_cavity', False)
        set_if(shading, 'show_specular_highlight', False)
        set_if(shading, 'background_color', (0.0, 0.0, 0.0))
        set_if(scene.display, 'render_aa', 'OFF')
        try:
            scene.view_settings.view_transform = 'Raw'
        except Exception:
            scene.view_settings.view_transform = 'Standard'
        try:
            scene.view_settings.look = 'None'
        except Exception:
            pass
    else:
        set_if(shading, 'light', 'STUDIO')
        set_if(shading, 'show_shadows', True)
        set_if(shading, 'show_cavity', True)
        set_if(shading, 'cavity_type', 'WORLD')
        set_if(shading, 'curvature_ridge_factor', 1.35)
        set_if(shading, 'curvature_valley_factor', 0.85)
        set_if(shading, 'show_specular_highlight', True)
        set_if(shading, 'background_color', (0.003, 0.010, 0.026))
        set_if(scene.display, 'render_aa', '8')
        try:
            scene.view_settings.view_transform = 'Standard'
        except Exception:
            pass
        try:
            scene.view_settings.look = 'Medium High Contrast'
        except Exception:
            try:
                scene.view_settings.look = 'None'
            except Exception:
                pass

    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    return scene, coll


def add_camera(scene, min_v, max_v):
    center = (min_v + max_v) * 0.5
    size = max_v - min_v
    camera_data = bpy.data.cameras.new(scene.name + ' camera')
    camera = bpy.data.objects.new(scene.name + ' camera', camera_data)
    scene.collection.objects.link(camera)
    camera_data.type = 'ORTHO'

    visible_h = max(size.z * 1.08, (size.x / ASPECT) * 1.08)
    camera_data.ortho_scale = max(visible_h, 0.1)
    distance = max(size.x, size.y, size.z, 0.1) * 3.2
    camera.location = Vector((center.x, min_v.y - distance, center.z))
    direction = center - camera.location
    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    scene.camera = camera
    return center, camera_data.ortho_scale


def project_anchor(center, camera_center, ortho_scale):
    world_w = ortho_scale * ASPECT
    left = camera_center.x - world_w / 2
    bottom = camera_center.z - ortho_scale / 2
    x = (center.x - left) / world_w
    y = 1 - ((center.z - bottom) / ortho_scale)
    return [round(max(0.02, min(0.98, x)), 5), round(max(0.02, min(0.98, y)), 5)]


def unique_objects(rows):
    out = []
    seen = set()
    for obj in rows:
        try:
            ptr = obj.as_pointer()
        except Exception:
            continue
        if ptr in seen:
            continue
        seen.add(ptr)
        out.append(obj)
    return out


def render_pass(system, source_objects, bone_objects, id_pass=False):
    original_scene = bpy.context.window.scene
    scene, coll = setup_scene(f'FTR atlas {"id" if id_pass else "beauty"} {system}', id_pass=id_pass)

    render_objects = list(source_objects)
    if system in REFERENCE_SYSTEMS:
        render_objects = list(bone_objects) + render_objects
    render_objects = unique_objects(render_objects)

    saved = []
    try:
        for obj in render_objects:
            saved.append((obj, tuple(obj.color), bool(obj.hide_render), bool(obj.hide_viewport)))
            obj.hide_render = False
            obj.hide_viewport = False
            coll.objects.link(obj)

        if system in REFERENCE_SYSTEMS:
            if id_pass:
                ref = (0.0, 0.0, 0.0, 1.0)
            elif system == 'ligament':
                # Locked ligament reference: ivory/cream skeletal context, with
                # ligaments remaining lighter and the selected ATFL turning purple.
                ref = (0.72, 0.66, 0.56, 1.0)
            else:
                # Vessels/nerves keep a subdued neutral skeleton so their colored
                # trees remain the dominant information layer.
                ref = (0.18, 0.20, 0.25, 1.0)
            for obj in bone_objects:
                try:
                    obj.color = ref
                except Exception:
                    pass

        for index, obj in enumerate(source_objects):
            try:
                obj.color = id_rgba(index) if id_pass else beauty_rgba(system, obj.name)
            except Exception:
                pass

        min_v, max_v = bbox_world(render_objects)
        camera_center, ortho = add_camera(scene, min_v, max_v)
        scene.render.filepath = str(ATLAS / f'{system}-{"id" if id_pass else "front"}.png')

        bpy.context.window.scene = scene
        bpy.context.view_layer.update()
        print(f'[STATIC ATLAS] render {system} {"id" if id_pass else "beauty"}: {len(render_objects)} linked objects')
        bpy.ops.render.render(write_still=True)

        if id_pass:
            return None
        return [project_anchor(object_center(obj), camera_center, ortho) for obj in source_objects]
    finally:
        bpy.context.window.scene = original_scene
        try:
            bpy.context.view_layer.update()
        except Exception:
            pass

        scene_name = scene.name
        coll_name = coll.name
        scene_ref = bpy.data.scenes.get(scene_name)
        if scene_ref is not None:
            bpy.data.scenes.remove(scene_ref)
        coll_ref = bpy.data.collections.get(coll_name)
        if coll_ref is not None and coll_ref.users == 0:
            bpy.data.collections.remove(coll_ref)

        for obj, color, hide_render, hide_viewport in saved:
            try:
                obj.color = color
                obj.hide_render = hide_render
                obj.hide_viewport = hide_viewport
            except Exception:
                pass


def validate_presentation(system, rows):
    labels = [row['name'] for row in rows]

    bad_system = [label for label in labels if SYSTEM_TEXT_ARTIFACT.search(label)]
    if bad_system:
        raise RuntimeError(f'{system}: system text mesh leaked into atlas: {bad_system[:3]}')

    if system == 'muscle':
        bad_overlay = [label for label in labels if MUSCLE_PRESENTATION_EXCLUDE.search(label)]
        if bad_overlay:
            raise RuntimeError(f'Muscle presentation overlay leak: {bad_overlay[:8]}')
        if not any(re.search(r'tensor\s+fasciae\s+latae', label, re.I) for label in labels):
            raise RuntimeError('Muscle cleanup was too broad: Tensor fasciae latae missing')

    if system == 'vessel' and not any(re.search(r'anterior\s+tibial\s+arter', label, re.I) for label in labels):
        raise RuntimeError('Vascular curve extraction incomplete: Anterior tibial artery missing')

    if system == 'nerve':
        if not any(norm(label) in PREFERRED_EXACT['nerve'] for label in labels):
            raise RuntimeError('Neural curve extraction incomplete: whole Median nerve missing')
        first_median = next((label for label in labels if re.search(r'median\s+nerve|medianus', label, re.I)), '')
        if norm(first_median) not in PREFERRED_EXACT['nerve']:
            raise RuntimeError(f'Initial nerve selection would resolve to a branch: {first_median}')


def run():
    resolved = {system: resolve_collection(candidates) for system, candidates, _, _ in SYSTEMS}

    bone_objects = collection_objects(resolved['bone'], 'bone')
    muscle_objects = collection_objects(resolved['muscle'], 'muscle')

    # Remove muscle cross-links from vascular/neural atlases while retaining the
    # actual central nervous, cardiac and CURVE structures.
    muscle_keys = {norm(display_name(obj.name)) for obj in muscle_objects if display_name(obj.name)}

    manifest = {
        'version': 4,
        'render_mode': 'static-layered-atlas',
        'width': WIDTH,
        'height': HEIGHT,
        'systems': {},
        'policy': {
            'webgl': False,
            'continuous_render_loop': False,
            'runtime_3d_models': False,
            'selection': 'id-map + 2d highlight mask',
            'low_end_phone_first': True,
            'atlas_renderer': 'Blender Workbench linked-object render',
            'vascular_neural_curves': True,
            'muscle_context_removed_from_vessel_nerve': True,
            'muscle_surface_overlays_removed': True,
            'system_text_artifacts_removed': True,
            'exact_default_structure_priority': True,
            'ligament_ivory_skeleton_reference': True,
        },
    }

    for system, _, name_filter, allowed_types in SYSTEMS:
        if system == 'bone':
            source_objects = bone_objects
        elif system == 'muscle':
            source_objects = muscle_objects
        else:
            exclude = muscle_keys if system in {'vessel', 'nerve'} else set()
            source_objects = collection_objects(
                resolved[system],
                system,
                name_filter,
                allowed_types=allowed_types,
                exclude_keys=exclude,
            )

        type_counts = Counter(obj.type for obj in source_objects)
        print(f'[STATIC ATLAS] {system}: {len(source_objects)} structures / {dict(type_counts)}')

        anchors = render_pass(system, source_objects, bone_objects, id_pass=False)
        render_pass(system, source_objects, bone_objects, id_pass=True)

        rows = []
        for index, source in enumerate(source_objects):
            label = display_name(source.name)
            if len(label) < 2:
                continue
            rows.append({
                'id': index + 1,
                'rgb': id_rgb(index),
                'name': label,
                'raw': source.name,
                'key': norm(label),
                'object_type': source.type,
                'anchor': anchors[index],
            })

        validate_presentation(system, rows)
        manifest['systems'][system] = {
            'beauty': f'atlas/{system}-front.png',
            'id_map': f'atlas/{system}-id.png',
            'structure_count': len(rows),
            'object_types': dict(type_counts),
            'structures': rows,
        }

    (DATA / 'atlas-map.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    print(json.dumps({key: value['structure_count'] for key, value in manifest['systems'].items()}, indent=2))


run()
