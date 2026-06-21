from PIL import Image, ImageDraw, ImageChops

LEAF_GREEN = (46, 83, 57, 255)  # #2E5339
BANANA_YELLOW = (232, 169, 75, 255)  # #E8A94B
VEIN_COLOR = (255, 255, 255, 110)
SIZE = 1024


def make_leaf(size, leaf_color, scale):
    """Pointed leaf shape: the intersection (lens) of two offset circles,
    plus a center vein and a small stem at the bottom tip."""
    box = int(size * scale * 1.6)
    radius = int(box * 0.62)
    offset = int(radius * 0.95)

    mask_a = Image.new("L", (box, box), 0)
    ImageDraw.Draw(mask_a).ellipse(
        [box / 2 - radius, box / 2 - radius - offset / 2, box / 2 + radius, box / 2 + radius - offset / 2],
        fill=255,
    )
    mask_b = Image.new("L", (box, box), 0)
    ImageDraw.Draw(mask_b).ellipse(
        [box / 2 - radius, box / 2 - radius + offset / 2, box / 2 + radius, box / 2 + radius + offset / 2],
        fill=255,
    )
    lens_mask = ImageChops.multiply(mask_a, mask_b).point(lambda v: 255 if v > 127 else 0)

    leaf_img = Image.new("RGBA", (box, box), (0, 0, 0, 0))
    leaf_img.paste(Image.new("RGBA", (box, box), leaf_color), (0, 0), lens_mask)

    bbox = lens_mask.getbbox()
    ld = ImageDraw.Draw(leaf_img)
    if bbox:
        x0, y0, x1, y1 = bbox
        ld.line([(box / 2, y0 + (y1 - y0) * 0.08), (box / 2, y1 - (y1 - y0) * 0.08)],
                fill=VEIN_COLOR, width=max(2, int(size * 0.01)))
        stem_w = max(3, int(size * 0.012))
        ld.line([(box / 2, y1 - 2), (box / 2, min(box - 1, y1 + int((y1 - y0) * 0.12)))],
                fill=leaf_color, width=stem_w)

    leaf_img = leaf_img.rotate(-35, expand=True, resample=Image.BICUBIC)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    lx = (size - leaf_img.width) // 2
    ly = (size - leaf_img.height) // 2
    canvas.alpha_composite(leaf_img, (lx, ly))
    return canvas


# Flat icon (used directly on iOS/web/older Android): green bg, larger leaf.
flat = Image.new("RGBA", (SIZE, SIZE), LEAF_GREEN)
flat.alpha_composite(make_leaf(SIZE, BANANA_YELLOW, scale=0.62))
flat.convert("RGB").save("assets-icon/icon_flat.png")

# Adaptive icon foreground (Android 8+): transparent bg, smaller leaf to
# respect the safe zone the OS uses when masking/animating the icon shape.
foreground = make_leaf(SIZE, BANANA_YELLOW, scale=0.42)
foreground.save("assets-icon/icon_foreground.png")

print("Icons generated.")
