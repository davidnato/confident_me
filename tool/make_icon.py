"""Draws the ConfidentMe launcher icon (a lotus on a soft lavender gradient).

Run from the project root:  python3 tool/make_icon.py
Needs Pillow (pip install pillow). Writes three files to assets/icon/:
  icon.png             full square icon (older Android versions)
  icon_background.png  gradient layer of the adaptive icon
  icon_foreground.png  transparent lotus layer of the adaptive icon
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SS = 3                      # draw 3x larger, then shrink for smooth edges
BIG = SIZE * SS

TOP = (143, 129, 232)       # lighter lavender
BOTTOM = (82, 66, 190)      # deeper indigo (matches the app's seed 6A5ACD family)
TEAL = (122, 219, 208)


def gradient():
    img = Image.new("RGB", (BIG, BIG))
    px = img.load()
    for y in range(BIG):
        t = y / (BIG - 1)
        row = tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        for x in range(BIG):
            px[x, y] = row
    return img.convert("RGBA")


def petal(length, width, angle_deg, base, fill):
    """One pointed petal growing from `base`, tilted by angle (0 = straight up)."""
    pts_l, pts_r = [], []
    steps = 80
    for i in range(steps + 1):
        s = i / steps
        w = width * (math.sin(math.pi * s) ** 0.85) * (1.0 - 0.18 * s)
        pts_l.append((-w, -s * length))
        pts_r.append((w, -s * length))
    pts = pts_l + pts_r[::-1]
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    placed = [(base[0] + x * ca - y * sa, base[1] + x * sa + y * ca) for x, y in pts]
    layer = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(placed, fill=fill)
    return layer


def lotus(scale):
    """Transparent layer with the lotus, centred. `scale` 1.0 fills ~70% of the canvas."""
    layer = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
    cx = BIG / 2
    base = (cx, BIG * (0.5 + 0.30 * scale))
    L = BIG * 0.60 * scale
    W = BIG * 0.115 * scale

    # soft glow behind the flower
    glow = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
    r = BIG * 0.30 * scale
    gc = (cx, BIG * (0.5 - 0.02 * scale))
    ImageDraw.Draw(glow).ellipse([gc[0] - r, gc[1] - r, gc[0] + r, gc[1] + r],
                                 fill=(255, 255, 255, 46))
    glow = glow.filter(ImageFilter.GaussianBlur(BIG * 0.05))
    layer = Image.alpha_composite(layer, glow)

    # petals, back to front: outer pair, middle pair, centre
    for angle, ln, wd, alpha in [(-64, 0.72, 0.95, 150), (64, 0.72, 0.95, 150),
                                 (-32, 0.88, 1.0, 205), (32, 0.88, 1.0, 205),
                                 (0, 1.0, 1.05, 255)]:
        layer = Image.alpha_composite(
            layer, petal(L * ln, W * wd, angle, base, (255, 255, 255, alpha)))

    # a small teal dot above the flower: one small step
    d = ImageDraw.Draw(layer)
    dr = BIG * 0.028 * scale
    dc = (cx, base[1] - L * 1.0 - BIG * 0.045 * scale)
    d.ellipse([dc[0] - dr, dc[1] - dr, dc[0] + dr, dc[1] + dr], fill=TEAL + (255,))
    return layer


def shrink(img):
    return img.resize((SIZE, SIZE), Image.LANCZOS)


bg = gradient()
full = Image.alpha_composite(bg, lotus(1.0))
shrink(full).convert("RGB").save("assets/icon/icon.png")
shrink(bg).convert("RGB").save("assets/icon/icon_background.png")
# Adaptive icons are cropped to a circle or squircle, so keep the flower smaller
# and well inside the central safe area.
shrink(lotus(0.72)).save("assets/icon/icon_foreground.png")
print("wrote assets/icon/icon.png, icon_background.png, icon_foreground.png")
