from PIL import Image
import os

filepath = 'Sprite/Environment/espantalho_summon-Sheet.png'
if os.path.exists(filepath):
    img = Image.open(filepath)
    w, h = img.size
    
    frame_w = 512
    frame_h = 512
    frames = w // frame_w
    
    columns = 10
    rows = (frames + columns - 1) // columns
    
    new_w = columns * frame_w
    new_h = rows * frame_h
    
    new_img = Image.new('RGBA', (new_w, new_h))
    
    for i in range(frames):
        x = (i % columns) * frame_w
        y = (i // columns) * frame_h
        
        src_x = i * frame_w
        frame_img = img.crop((src_x, 0, src_x + frame_w, frame_h))
        new_img.paste(frame_img, (x, y))
        
    new_img.save('Sprite/Environment/espantalho_summon_grid.png')
    img.close()
    
    os.remove(filepath)
    if os.path.exists(filepath + '.import'):
        os.remove(filepath + '.import')
    print("Converted successfully to espantalho_summon_grid.png")
else:
    print("File not found")
