extends SceneTree

func _init():
	var frames = SpriteFrames.new()
	
	var anims = [
		{"name": "idle", "path": "res://Sprite/NPC/Necromancer/Necromancer/Idle/spr_NecromancerIdle_strip50.png", "count": 50, "fps": 10, "loop": true},
		{"name": "move", "path": "res://Sprite/NPC/Necromancer/Necromancer/Walk/spr_NecromancerWalk_strip10.png", "count": 10, "fps": 10, "loop": true},
		{"name": "attack", "path": "res://Sprite/NPC/Necromancer/Necromancer/Attack/spr_NecromancerAttackWithEffect_strip47.png", "count": 47, "fps": 15, "loop": false},
		{"name": "hurt", "path": "res://Sprite/NPC/Necromancer/Necromancer/GetHit/spr_NecromancerGetHit_strip9.png", "count": 9, "fps": 10, "loop": false},
		{"name": "death", "path": "res://Sprite/NPC/Necromancer/Necromancer/Death/spr_NecromancerDeath_strip52.png", "count": 52, "fps": 15, "loop": false}
	]
	
	for anim in anims:
		frames.add_animation(anim.name)
		frames.set_animation_speed(anim.name, anim.fps)
		frames.set_animation_loop(anim.name, anim.loop)
		
		var tex: Texture2D = load(anim.path)
		if not tex:
			print("Failed to load: ", anim.path)
			continue
			
		var w = tex.get_width() / anim.count
		var h = tex.get_height()
		
		for i in range(anim.count):
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * w, 0, w, h)
			atlas.filter_clip = true
			frames.add_frame(anim.name, atlas)
			
	ResourceSaver.save(frames, "res://Sprite/NPC/NecromancerFrames.tres")
	print("Saved NecromancerFrames.tres successfully!")
	quit()
