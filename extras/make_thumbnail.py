# Renders thumbnail.png from screenshot.png. Run from this directory:
#   python3 make_thumbnail.py
import math

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

SRC = "screenshot.png"
OUT = "thumbnail.png"
W, H = 2560, 1280  # GitHub social preview ratio (2:1)
SS = 2  # supersampling for clean edges on the tilted window

FONTS = "/usr/share/fonts/TTF/"
F_BOLD = FONTS + "JetBrainsMonoNerdFont-Bold.ttf"
F_REG = FONTS + "JetBrainsMonoNerdFont-Regular.ttf"

BG = (14, 14, 16)
CHERRY = (226, 69, 95)  # Obsidian Cherry palette (lua/core/obsidian_syntax.lua)
PURPLE = (167, 123, 240)

shot = Image.open(SRC).convert("RGB")


def build_window():
    """Crop to the code (the right side of the screenshot is empty) and keep
    the statusline's right half, with a plain title bar like kitty's."""
    cw, top, bottom = 1300, 28, 990
    body = shot.crop((0, top, cw, bottom))
    # utf-8 / cpp / 31:14 / 75%, plus the margin after it, flush to the edge
    seg = shot.crop((1240, 950, shot.size[0], 978))
    body.paste(seg, (cw - seg.size[0], 950 - top))

    bar_h = 44
    win = Image.new("RGB", (cw, body.size[1] + bar_h), (30, 30, 34))
    win.paste(body, (0, bar_h))
    d = ImageDraw.Draw(win)
    f = ImageFont.truetype(F_REG, 17)
    label = "nvim main.cpp"
    d.text(((cw - d.textlength(label, font=f)) / 2, bar_h / 2 - 11), label, font=f, fill=(170, 170, 176))

    mask = Image.new("L", win.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, win.size[0] - 1, win.size[1] - 1), 14, fill=255)
    win = win.convert("RGBA")
    win.putalpha(mask)
    ImageDraw.Draw(win).rounded_rectangle(
        (0, 0, win.size[0] - 1, win.size[1] - 1), 14, outline=(255, 255, 255, 22), width=2
    )
    return win


def project(size, rot_y, rot_x, scale, center, focal=2600):
    """Rotate the window's corners in 3D and perspective-project them."""
    w, h = size
    pts = np.array([[-w / 2, -h / 2, 0], [w / 2, -h / 2, 0], [w / 2, h / 2, 0], [-w / 2, h / 2, 0]])
    ay, ax = math.radians(rot_y), math.radians(rot_x)
    ry = np.array([[math.cos(ay), 0, math.sin(ay)], [0, 1, 0], [-math.sin(ay), 0, math.cos(ay)]])
    rx = np.array([[1, 0, 0], [0, math.cos(ax), -math.sin(ax)], [0, math.sin(ax), math.cos(ax)]])
    p = pts @ (rx @ ry).T
    z = p[:, 2] + focal
    return [(center[0] + scale * focal * x / zz, center[1] + scale * focal * y / zz) for (x, y, _), zz in zip(p, z)]


def coeffs(dst, src):
    """PIL PERSPECTIVE coefficients mapping output points back to input points."""
    a, b = [], []
    for (x, y), (u, v) in zip(dst, src):
        a.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        b.append(u)
        a.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        b.append(v)
    return np.linalg.solve(np.array(a, float), np.array(b, float)).tolist()


canvas = Image.new("RGBA", (W, H), BG + (255,))

# ── tilted window ─────────────────────────────────────────────────────────────
win = build_window()
win_w = 1420
win = win.resize((win_w, int(win_w * win.size[1] / win.size[0])), Image.LANCZOS)
ww, wh = win.size

quad = project((ww, wh), rot_y=-20, rot_x=6, scale=0.84, center=(1820, 640))
big = win.resize((ww * SS, wh * SS), Image.LANCZOS)
src = [(0, 0), (ww * SS, 0), (ww * SS, wh * SS), (0, wh * SS)]
dst = [(x * SS, y * SS) for x, y in quad]
warped = big.transform((W * SS, H * SS), Image.PERSPECTIVE, coeffs(dst, src), Image.BICUBIC)
warped = warped.resize((W, H), Image.LANCZOS)

# Slight depth of field on the far edge. Only the content is blurred: the
# window's outline keeps its sharp alpha so the edge doesn't smear.
xx = np.arange(W, dtype=np.float32)[None, :].repeat(H, 0)
dof = Image.fromarray((np.clip((xx - 2200) / 400, 0, 1) * 255).astype(np.uint8), "L")
edge_alpha = warped.getchannel("A")
blurred = warped.filter(ImageFilter.GaussianBlur(3))
blurred.putalpha(edge_alpha)
warped = Image.composite(blurred, warped, dof)

# One soft, neutral shadow
alpha = warped.getchannel("A")
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
shadow.putalpha(ImageChops.offset(alpha, -24, 40).filter(ImageFilter.GaussianBlur(45)).point(lambda a: a * 0.7))
canvas.alpha_composite(shadow)

# Faint border glow behind the window: cherry at the bottom-left into purple at
# the top-right. Drawn underneath, so it only shows just outside the edge.
yy = np.arange(H, dtype=np.float32)[:, None].repeat(W, 1)
t = np.clip(((xx - 1150) / 1300) * 0.6 + ((1100 - yy) / 1000) * 0.4, 0, 1)[..., None]
tint = (np.array(CHERRY) * (1 - t) + np.array(PURPLE) * t).astype(np.uint8)
glow = Image.fromarray(tint, "RGB").convert("RGBA")
glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(22)).point(lambda a: a * 0.32))
canvas.alpha_composite(glow)
canvas.alpha_composite(warped)

# ── type ──────────────────────────────────────────────────────────────────────
d = ImageDraw.Draw(canvas)
x0 = 160
f_title = ImageFont.truetype(F_BOLD, 112)
f_sub = ImageFont.truetype(F_REG, 46)
f_small = ImageFont.truetype(F_REG, 30)

d.text((x0, 432), "~/.config/nvim", font=f_small, fill=(100, 100, 110))

title = "nvim config"
d.text((x0, 470), title, font=f_title, fill=(236, 236, 240))
# thin insert-mode cursor after the title, in the cherry used for keywords
tb = d.textbbox((x0, 470), title, font=f_title)
cx = tb[2] + 18
d.rectangle((cx, tb[1] + 4, cx + 8, tb[3] + 2), fill=CHERRY)

d.text((x0, 640), "a Neovim setup tuned for C/C++", font=f_sub, fill=(150, 150, 160))
d.text((x0, 1150), "github.com/snytex/nvim-config-files", font=f_small, fill=(95, 95, 104))

canvas.convert("RGB").save(OUT, optimize=True)
print("saved", OUT, canvas.size)
