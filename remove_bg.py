from PIL import Image

def remove_background(filepath, bg_color):
    img = Image.open(filepath).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        if item == bg_color:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(filepath)
    print(f"Removed background {bg_color} from {filepath}")

remove_background('Sprite/Environment/espantalho_summon_grid.png', (79, 23, 135, 255))
