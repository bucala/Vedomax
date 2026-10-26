"""Blender background pipeline for the supplied Meshy OBJ, never edits a live scene.

Usage: blender --background --factory-startup --python scripts/animate_mascot.py -- --preview
"""
import argparse
import json
import math
from pathlib import Path
import sys
import heapq

import bpy
from mathutils import Vector, Quaternion

ROOT=Path(__file__).resolve().parents[1]
args=argparse.ArgumentParser()
args.add_argument('--preview',action='store_true')
args.add_argument('--source',default=str(Path.home()/'Downloads/Meshy_AI_Vivi_20261026_texture.obj'))
options=args.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
OUT=ROOT/'output/mascot'
OUT.mkdir(parents=True,exist_ok=True)

def aim(obj,point):
    obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()

def setup():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.wm.obj_import(filepath=str(Path(options.source).resolve()))
    meshes=[o for o in bpy.context.selected_objects if o.type=='MESH']
    bpy.context.view_layer.objects.active=meshes[0]
    if len(meshes)>1: bpy.ops.object.join()
    mesh=bpy.context.view_layer.objects.active
    mesh.name='Vedomax_Mesh'
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bounds=[mesh.matrix_world@Vector(v) for v in mesh.bound_box]
    lo=Vector(tuple(min(p[i] for p in bounds) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in bounds) for i in range(3)))
    print('IMPORTED_BOUNDS',list(lo),list(hi),flush=True)
    scale=2.4/(hi.z-lo.z)
    center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    for v in mesh.data.vertices: v.co=(v.co-center)*scale
    mesh.location=(0,0,0)
    for p in mesh.data.polygons:p.use_smooth=True
    texture=Path(options.source).with_suffix('.png')
    material=bpy.data.materials.new('Vedomax_Original_Texture')
    material.use_nodes=True
    bsdf=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    tex=material.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image=bpy.data.images.load(str(texture),check_existing=True)
    material.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
    if 'Emission Color' in bsdf.inputs:
        material.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Emission Color'])
        bsdf.inputs['Emission Strength'].default_value=.2
    bsdf.inputs['Roughness'].default_value=.72
    bsdf.inputs['Metallic'].default_value=0
    mesh.data.materials.clear();mesh.data.materials.append(material)
    scene=bpy.context.scene
    engines=scene.render.bl_rna.properties['engine'].enum_items
    scene.render.engine=next(e.identifier for e in engines if 'EEVEE' in e.identifier)
    scene.render.resolution_x=384;scene.render.resolution_y=384
    scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG'
    scene.render.image_settings.color_mode='RGBA'
    scene.render.image_settings.color_depth='8'
    scene.world.color=(.28,.28,.28)
    scene.view_settings.view_transform='Standard'
    for name,position,power,size in [
        ('Key',(-3,-4,6),650,5),('Fill',(4,-2,3),400,4),('Rim',(0,3,5),550,3)]:
        data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
        light=bpy.data.objects.new(name,data);scene.collection.objects.link(light)
        light.location=position;aim(light,(0,0,1.2))
    camera_data=bpy.data.cameras.new('Vedomax_Camera');camera_data.type='ORTHO';camera_data.ortho_scale=3.2
    camera=bpy.data.objects.new('Vedomax_Camera',camera_data);scene.collection.objects.link(camera)
    camera.location=(0,-6,1.3);aim(camera,(0,0,1.22));scene.camera=camera
    return mesh,scene,camera

mesh,scene,camera=setup()
if options.preview:
    for name,position in [('front',(0,-6,1.3)),('back',(0,6,1.3))]:
        camera.location=position;aim(camera,(0,0,1.22))
        scene.render.filepath=str(OUT/f'preview_{name}.png')
        bpy.ops.render.render(write_still=True)
    (OUT/'inspection.json').write_text(json.dumps({'vertices':len(mesh.data.vertices),'faces':len(mesh.data.polygons),
        'dimensions':list(mesh.dimensions),'object':mesh.name},indent=2))
else:
    # OBJ has no skeleton. Build a small deformation rig and geodesic hand weights.
    bpy.ops.object.select_all(action='DESELECT')
    mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
    rig_data=bpy.data.armatures.new('Vedomax_Rig')
    rig=bpy.data.objects.new('Vedomax_Rig',rig_data);scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);mesh.select_set(False)
    bpy.ops.object.mode_set(mode='EDIT')
    for name,head,tail,parent in [
        ('root',(0,0,0),(0,0,.6),None),
        ('wave_arm',(.48,0,.84),(.74,0,.94),'root'),
        ('wave_hand',(.74,0,.94),(.89,0,1.38),'wave_arm'),
        ('sparkle',(.65,0,2.16),(.65,0,2.4),'root')]:
        bone=rig_data.edit_bones.new(name);bone.head=head;bone.tail=tail
        if parent:bone.parent=rig_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    coords=[v.co.copy() for v in mesh.data.vertices]
    graph=[[] for _ in coords]
    for edge in mesh.data.edges:
        a,b=edge.vertices;distance=(coords[a]-coords[b]).length
        graph[a].append((b,distance));graph[b].append((a,distance))
    def distances(seed,limit):
        result={seed:0};queue=[(0,seed)]
        while queue:
            dist,index=heapq.heappop(queue)
            if dist>result[index]:continue
            for neighbor,length in graph[index]:
                value=dist+length
                if value<=limit and value<result.get(neighbor,float('inf')):
                    result[neighbor]=value;heapq.heappush(queue,(value,neighbor))
        return result
    seed=min((i for i,p in enumerate(coords) if p.x>.7 and 1.05<p.z<1.5),key=lambda i:(coords[i]-Vector((.89,-.15,1.18))).length)
    wave_distances=distances(seed,.9)
    star_seed=max(range(len(coords)),key=lambda i:coords[i].z)
    star_distances=distances(star_seed,.65)
    groups={name:mesh.vertex_groups.new(name=name) for name in ['root','wave_arm','wave_hand','sparkle']}
    def smooth(value):
        v=max(0,min(1,value));return v*v*(3-2*v)
    for i,p in enumerate(coords):
        star=1 if i in star_distances else 0
        distance=wave_distances.get(i,10)
        wave=smooth((.85-distance)/.30) if p.x>.45 and p.z<1.62 else 0
        hand=wave*smooth((p.z-.90)/.24)
        upper=wave-hand
        root=1-star-wave
        if root>0:groups['root'].add([i],root,'REPLACE')
        if upper>0:groups['wave_arm'].add([i],upper,'REPLACE')
        if hand>0:groups['wave_hand'].add([i],hand,'REPLACE')
        if star>0:groups['sparkle'].add([i],star,'REPLACE')
    mesh.parent=rig
    modifier=mesh.modifiers.new('Vedomax_Deformation','ARMATURE');modifier.object=rig
    rig.show_in_front=True
    rig.animation_data_create()
    scene.render.fps=20
    scene.frame_start=1;scene.frame_end=60
    scene.render.resolution_x=384;scene.render.resolution_y=384
    local_axes={name:bone.bone.matrix_local.to_3x3().inverted()@Vector((0,1,0)) for name,bone in rig.pose.bones.items()}
    actions={}
    for name,count in [('Idle_Wave',60),('Celebrate',36)]:
        action=bpy.data.actions.new(name);action.use_fake_user=True
        rig.animation_data.action=action
        for frame in range(1,count+1):
            t=(frame-1)/count*math.tau
            success=name=='Celebrate'
            rig.location=(0,0,(.15*math.sin(t/2)**2 if success else .018*(1-math.cos(t))))
            rig.rotation_euler=(0,math.radians(3 if success else 1.7)*math.sin(t),math.radians(5 if success else 2.5)*math.sin(t))
            rig.scale=(1+.012*math.sin(t),1+.012*math.sin(t),1-.008*math.sin(t))
            for path in ['location','rotation_euler','scale']:rig.keyframe_insert(data_path=path,frame=frame,group='Body')
            wave_envelope=math.sin(t/2)**2
            for bone_name,angle in [
                ('wave_arm',math.radians(9 if success else 4)*math.sin(t)),
                ('wave_hand',math.radians(17 if success else 12)*math.sin(t*3)*wave_envelope),
                ('sparkle',math.radians(13)*math.sin(t))]:
                bone=rig.pose.bones[bone_name];bone.rotation_mode='QUATERNION'
                bone.rotation_quaternion=Quaternion(local_axes[bone_name],angle)
                bone.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=bone_name)
            star=rig.pose.bones['sparkle'];star.location=(0,0,.035*math.sin(t))
            star.keyframe_insert(data_path='location',frame=frame,group='sparkle')
        actions[name]=(action,count)
    rig.animation_data.action=actions['Idle_Wave'][0]
    scene.frame_set(1)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vedomax_animated.blend'),compress=True)
    export_args=dict(filepath=str(OUT/'vedomax_animated.glb'),export_format='GLB',use_selection=True,export_animations=True)
    available=bpy.ops.export_scene.gltf.get_rna_type().properties
    if 'export_animation_mode' in available:export_args['export_animation_mode']='ACTIONS'
    mesh.select_set(True);rig.select_set(True)
    bpy.ops.export_scene.gltf(**export_args)
    for clip,(action,count) in actions.items():
        rig.animation_data.action=action
        scene.frame_end=count
        frame_dir=OUT/'frames'/clip.lower();frame_dir.mkdir(parents=True,exist_ok=True)
        for frame in range(1,count+1):
            scene.frame_set(frame)
            scene.render.filepath=str(frame_dir/f'{frame:04d}.png')
            bpy.ops.render.render(write_still=True)
            if frame%10==0:print('FRAME_PROGRESS',clip,frame,count,flush=True)
    print('ANIMATION_COMPLETE',flush=True)
