import os
from PIL import Image

def gen_tres():
    anims = [
        ("idle", "res://Sprite/NPC/Necromancer/Necromancer/Idle/spr_NecromancerIdle_strip50.png", 50, 10, True, 96),
        ("move", "res://Sprite/NPC/Necromancer/Necromancer/Walk/spr_NecromancerWalk_strip10.png", 10, 10, True, 96),
        ("attack", "res://Sprite/NPC/Necromancer/Necromancer/Attack/spr_NecromancerAttackWithEffect_strip47.png", 47, 15, False, 128),
        ("hurt", "res://Sprite/NPC/Necromancer/Necromancer/GetHit/spr_NecromancerGetHit_strip9.png", 9, 10, False, 96),
        ("death", "res://Sprite/NPC/Necromancer/Necromancer/Death/spr_NecromancerDeath_strip52.png", 52, 15, False, 96)
    ]
    
    ext_resources = []
    for i, anim in enumerate(anims):
        ext_resources.append(f'[ext_resource type="Texture2D" path="{anim[1]}" id="{i+1}"]')
        
    sub_resources = []
    anim_nodes = []
    
    for i, anim in enumerate(anims):
        anim_name, path, count, fps, loop, frame_size = anim
        ext_id = i + 1
        
        frames_list = []
        for frame in range(count):
            sub_id = f"AtlasTexture_{anim_name}_{frame}"
            sub_resources.append(f'[sub_resource type="AtlasTexture" id="{sub_id}"]')
            sub_resources.append(f'atlas = ExtResource("{ext_id}")')
            sub_resources.append(f'region = Rect2({frame * frame_size}, 0, {frame_size}, {frame_size})')
            sub_resources.append('filter_clip = true')
            sub_resources.append('')
            
            frames_list.append(f'{{\n"duration": 1.0,\n"texture": SubResource("{sub_id}")\n}}')
            
        frames_str = ", ".join(frames_list)
        loop_str = "true" if loop else "false"
        anim_nodes.append(f'{{\n"frames": [{frames_str}],\n"loop": {loop_str},\n"name": &"{anim_name}",\n"speed": {fps}.0\n}}')
        
    anim_str = ", ".join(anim_nodes)
    
    content = f'[gd_resource type="SpriteFrames" load_steps=200 format=3]\n\n'
    content += "\n".join(ext_resources) + "\n\n"
    content += "\n".join(sub_resources)
    content += f'\n[resource]\nanimations = [{anim_str}]\n'
    
    with open('Sprite/NPC/NecromancerFrames.tres', 'w', encoding='utf-8') as f:
        f.write(content)

gen_tres()
