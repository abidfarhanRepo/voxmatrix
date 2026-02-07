#!/usr/bin/env python3
"""
VoxMatrix Icon Generator
Creates a professional app icon with Matrix theme
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math

# Icon sizes for Android mipmap folders
ICON_SIZES = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192
}

def create_voxmatrix_icon(size):
    """Create a VoxMatrix app icon"""
    
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions
    padding = int(size * 0.1)
    icon_size = size - (padding * 2)
    
    # Create circular background with gradient effect
    center = size // 2
    radius = icon_size // 2
    
    # Draw circular background with Matrix blue-purple gradient colors
    for y in range(size):
        for x in range(size):
            # Calculate distance from center
            dist = math.sqrt((x - center)**2 + (y - center)**2)
            if dist <= radius:
                # Create gradient from blue to purple
                ratio = dist / radius
                r = int(100 + (138 - 100) * ratio)  # Blue to purple
                g = int(150 + (43 - 150) * ratio)   # Mid tone
                b = int(255 - (60) * ratio)         # Light blue to purple
                img.putpixel((x, y), (r, g, b, 255))
    
    # Add subtle grid pattern (Matrix theme)
    grid_color = (255, 255, 255, 30)
    grid_spacing = max(4, size // 16)
    
    for i in range(padding, size - padding, grid_spacing):
        # Vertical lines
        draw.line([(i, padding), (i, size - padding)], fill=grid_color, width=1)
        # Horizontal lines  
        draw.line([(padding, i), (size - padding, i)], fill=grid_color, width=1)
    
    # Draw stylized "V" letter in white
    v_color = (255, 255, 255, 255)
    v_thickness = max(2, size // 12)
    
    # Calculate V position
    v_top_y = int(size * 0.25)
    v_bottom_y = int(size * 0.75)
    v_left_x = int(size * 0.35)
    v_right_x = int(size * 0.65)
    v_center_x = size // 2
    
    # Draw V shape
    # Left stroke
    draw.line([(v_left_x, v_top_y), (v_center_x, v_bottom_y)], 
              fill=v_color, width=v_thickness)
    # Right stroke
    draw.line([(v_right_x, v_top_y), (v_center_x, v_bottom_y)], 
              fill=v_color, width=v_thickness)
    
    # Add glow effect around the V
    glow_color = (100, 200, 255, 100)
    glow_thickness = v_thickness + 4
    draw.line([(v_left_x, v_top_y), (v_center_x, v_bottom_y)], 
              fill=glow_color, width=glow_thickness)
    draw.line([(v_right_x, v_top_y), (v_center_x, v_bottom_y)], 
              fill=glow_color, width=glow_thickness)
    
    # Add subtle rounded corners mask
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = size // 8
    mask_draw.rounded_rectangle([0, 0, size, size], radius=corner_radius, fill=255)
    
    # Apply mask
    img.putalpha(mask)
    
    return img

def main():
    """Generate icons for all Android mipmap densities"""
    
    base_path = '/home/xaf/Desktop/VoxMatrix/app/android/app/src/main/res'
    
    print("Generating VoxMatrix app icons...")
    
    for folder, size in ICON_SIZES.items():
        # Create icon
        icon = create_voxmatrix_icon(size)
        
        # Save to mipmap folder
        mipmap_path = os.path.join(base_path, f'mipmap-{folder}')
        os.makedirs(mipmap_path, exist_ok=True)
        
        output_path = os.path.join(mipmap_path, 'ic_launcher.png')
        icon.save(output_path, 'PNG')
        
        print(f"Created {folder} icon ({size}x{size}): {output_path}")
    
    print("\nIcon generation complete!")
    print("Icons saved to: app/android/app/src/main/res/mipmap-*/")

if __name__ == '__main__':
    main()
