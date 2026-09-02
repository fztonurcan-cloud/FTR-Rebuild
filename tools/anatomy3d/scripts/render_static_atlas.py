import bpy
import json
import math
import os
import re
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
    ('muscle', ('4: Muscular system', 'Muscular system'), None),
    ('bone', ('1: Skeletal system', 'Skeletal system'), None),
    ('ligament', ('3: Joints', 'Joints'), re.compile(r'(ligament|retinacul)', re.I)),
    ('vessel', ('5: Cardiovascular system', 'Cardiovascular system'), None),
    ('nerve', ('6: Nervous system', 'Nervous system'), None),
]
REFERENCE_SYSTEMS = {'ligament', 'vessel', 'nerve'}
BONE_CANDIDATES = ('1: Skeletal system', 'Skeletal system')


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


def collection_objects(collection, name_filter=None):
    try:
        candidates = list(collection.all_objects)
    except Exception:
        candidates = []
        for child in [collection, *list(collection.children_recursive)]:
            try:
                candidates.extend(list(child.objects))
            except Exception:
                pass
    rows = []
    seen = set()
    for obj in candidates:
        try:
            ptr = obj.as_pointer()
            if ptr in seen or obj.type != 'MESH' or not obj.data or not obj.data.polygons:
                continue
            seen.add(ptr)
            if name_filter and not name_filter.search(obj.name):
                continue
            rows.append(obj)
        except Exception:
            continue
    if not rows:
        raise RuntimeError(f'No mesh objects for {collection.name}')
    return rows


def material(name, rgba, emission=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    for node in list(nodes):
        nodes.remove(node)
    out = nodes.new('ShaderNodeOutputMaterial')
    if emission:
        shader = nodes.new('ShaderNodeEmission')
        shader.inputs['Color'].default_value = rgba
        shader.inputs['Strength'].default_value = 1.0
    else:
        shader = nodes.new('ShaderNodeBsdfPrincipled')
        shader.inputs['Base Color'].default_value = rgba
        shader.inputs['Roughness'].default_value = 0.62
        if 'Specular IOR Level' in shader.inputs:
            shader.inputs['Specular IOR Level'].default_value = 0.28
        elif 'Specular' in shader.inputs:
            shader.inputs['Specular'].default_value = 0.28
    links.new(shader.outputs[0], out.inputs['Surface'])
    return mat


def beauty_rgba(system, raw_name):
    n = raw_name.lower()
    if system == 'muscle':
        if re.search(r'tendon|aponeuros|fascia', n):
            return (0.88, 0.82, 0.72, 1)
        return (0.62, 0.095, 0.055, 1)
    if system == 'bone':
        return (0.82, 0.75, 0.62, 1)
    if system == 'ligament':
        return (0.82, 0.78, 0.70, 1)
    if system == 'vessel':
        if re.search(r'vein|vena|venous|saphen', n):
            return (0.045, 0.18, 0.72, 1)
        return (0.82, 0.035, 0.055, 1)
    if system == 'nerve':
        if re.search(r'brain|cerebr|spinal cord|medulla', n):
            return (0.58, 0.40, 0.24, 1)
        return (0.96, 0.62, 0.015, 1)
    return (0.7, 0.7, 0.7, 1)


def id_rgba(index):
    value = index + 1
    return ((value & 255) / 255.0, ((value >> 8) & 255) / 255.0, ((value >> 16) & 255) / 255.0, 1.0)


def id_rgb(index):
    value = index + 1
    return [value & 255, (value >> 8) & 255, (value >> 16) & 255]


def duplicate_into(source, collection, mat):
    dup = source.copy()
    dup.data = source.data.copy()
    dup.parent = None
    dup.matrix_world = source.matrix_world.copy()
    dup.animation_data_clear()
    dup.constraints.clear()
    dup.modifiers.clear()
    dup.hide_render = False
    dup.hide_viewport = False
    dup.data.materials.clear()
    dup.data.materials.append(mat)
    collection.objects.link(dup)
    return dup


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


def setup_scene(name, world_color=(0.003, 0.010, 0.022, 1)):
    scene = bpy.data.scenes.new(name)
    coll = bpy.data.collections.new(name + ' objects')
    scene.collection.children.link(coll)
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = WIDTH
    scene.render.resolution_y = HEIGHT
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.film_transparent = False
    scene.render.image_settings.color_depth = '8'
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'Medium High Contrast'
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    scene.world = bpy.data.worlds.new(name + ' world')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = world_color
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.16
    return scene, coll


def add_camera(scene, min_v, max_v):
    center = (min_v + max_v) * 0.5
    size = max_v - min_v
    camera_data = bpy.data.cameras.new(scene.name + ' camera')
    camera = bpy.data.objects.new(scene.name + ' camera', camera_data)
    scene.collection.objects.link(camera)
    camera_data.type = 'ORTHO'
    # BodyParts3D/Z-Anatomy is authored upright on Z. View from anterior (-Y -> +Y).
    visible_h = max(size.z * 1.08, (size.x / ASPECT) * 1.08)
    camera_data.ortho_scale = max(visible_h, 0.1)
    distance = max(size.x, size.y, size.z, 0.1) * 3.2
    camera.location = Vector((center.x, min_v.y - distance, center.z))
    direction = center - camera.location
    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    scene.camera = camera
    return camera, center, camera_data.ortho_scale


def add_lights(scene, center, scale):
    hemi = bpy.data.lights.new(scene.name + ' key', type='AREA')
    hemi.energy = 820
    hemi.size = max(scale * 0.7, 1)
    key = bpy.data.objects.new(scene.name + ' key', hemi)
    key.location = (center.x - scale * .45, center.y - scale * .8, center.z + scale * .4)
    key.rotation_euler = (math.radians(64), 0, math.radians(-24))
    scene.collection.objects.link(key)

    fill_data = bpy.data.lights.new(scene.name + ' fill', type='AREA')
    fill_data.energy = 420
    fill_data.color = (0.35, 0.55, 1.0)
    fill_data.size = max(scale, 1)
    fill = bpy.data.objects.new(scene.name + ' fill', fill_data)
    fill.location = (center.x + scale * .6, center.y - scale * .5, center.z + scale * .1)
    fill.rotation_euler = (math.radians(70), 0, math.radians(145))
    scene.collection.objects.link(fill)


def project_anchor(center, camera_center, ortho_scale):
    world_w = ortho_scale * ASPECT
    left = camera_center.x - world_w / 2
    bottom = camera_center.z - ortho_scale / 2
    x = (center.x - left) / world_w
    y = 1 - ((center.z - bottom) / ortho_scale)
    return [round(max(0.02, min(0.98, x)), 5), round(max(0.02, min(0.98, y)), 5)]


def cleanup_scene(scene):
    objects = list(scene.objects)
    meshes = [obj.data for obj in objects if getattr(obj, 'type', None) == 'MESH' and obj.data]
    materials = []
    for mesh in meshes:
        materials.extend(list(mesh.materials))
    world = scene.world
    bpy.data.scenes.remove(scene)
    for obj in objects:
        if obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    for mesh in meshes:
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)
    for mat in materials:
        if mat and mat.users == 0:
            bpy.data.materials.remove(mat)
    if world and world.users == 0:
        bpy.data.worlds.remove(world)


def render_beauty(system, source_objects, bone_objects):
    scene, coll = setup_scene('FTR atlas beauty ' + system)
    duplicates = []
    cache = {}

    if system in REFERENCE_SYSTEMS:
        ref_mat = material('FTR reference ' + system, (0.22, 0.23, 0.23, 1))
        for source in bone_objects:
            duplicates.append(duplicate_into(source, coll, ref_mat))

    active_dups = []
    for source in source_objects:
        rgba = beauty_rgba(system, source.name)
        key = tuple(round(v, 3) for v in rgba)
        mat = cache.get(key)
        if mat is None:
            mat = material(f'FTR {system} beauty {len(cache)}', rgba)
            cache[key] = mat
        dup = duplicate_into(source, coll, mat)
        duplicates.append(dup)
        active_dups.append(dup)

    min_v, max_v = bbox_world(active_dups if system not in REFERENCE_SYSTEMS else duplicates)
    camera, center, ortho = add_camera(scene, min_v, max_v)
    add_lights(scene, center, ortho)
    scene.render.filepath = str(ATLAS / f'{system}-front.png')
    bpy.context.window.scene = scene
    bpy.context.view_layer.update()
    bpy.ops.render.render(write_still=True)

    anchors = [project_anchor(object_center(obj), center, ortho) for obj in active_dups]
    cleanup_scene(scene)
    return anchors


def render_id(system, source_objects, bone_objects):
    scene, coll = setup_scene('FTR atlas id ' + system, (0, 0, 0, 1))
    duplicates = []
    ref_mat = material('FTR id reference ' + system, (0, 0, 0, 1), emission=True)
    if system in REFERENCE_SYSTEMS:
        for source in bone_objects:
            duplicates.append(duplicate_into(source, coll, ref_mat))

    active_dups = []
    for index, source in enumerate(source_objects):
        mat = material(f'FTR id {system} {index}', id_rgba(index), emission=True)
        dup = duplicate_into(source, coll, mat)
        duplicates.append(dup)
        active_dups.append(dup)

    min_v, max_v = bbox_world(active_dups if system not in REFERENCE_SYSTEMS else duplicates)
    add_camera(scene, min_v, max_v)
    scene.render.filepath = str(ATLAS / f'{system}-id.png')
    scene.render.image_settings.color_mode = 'RGB'
    scene.render.film_transparent = False
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'None'
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    scene.render.image_settings.color_depth = '8'
    # Disable antialiasing for deterministic integer-color object IDs when supported.
    if hasattr(scene.render, 'use_antialiasing'):
        scene.render.use_antialiasing = False
    bpy.context.window.scene = scene
    bpy.context.view_layer.update()
    bpy.ops.render.render(write_still=True)
    cleanup_scene(scene)


def run():
    bone_objects = collection_objects(resolve_collection(BONE_CANDIDATES))
    manifest = {
        'version': 1,
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
        },
    }

    for system, candidates, name_filter in SYSTEMS:
        collection = resolve_collection(candidates)
        source_objects = collection_objects(collection, name_filter)
        print(f'[STATIC ATLAS] {system}: {len(source_objects)} structures')
        anchors = render_beauty(system, source_objects, bone_objects)
        render_id(system, source_objects, bone_objects)
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
                'anchor': anchors[index],
            })
        manifest['systems'][system] = {
            'beauty': f'atlas/{system}-front.png',
            'id_map': f'atlas/{system}-id.png',
            'structure_count': len(rows),
            'structures': rows,
        }

    (DATA / 'atlas-map.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({k: v['structure_count'] for k, v in manifest['systems'].items()}, indent=2))


run()
