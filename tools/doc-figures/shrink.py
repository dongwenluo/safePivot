"""Shrink the documentation PNGs (256-colour palette; screenshots lose nothing visible).
Usage (from the package root): python3 tools/doc-figures/shrink.py
Needs Pillow."""
import glob
from PIL import Image

for path in glob.glob("man/figures/README-*.png") + glob.glob("vignettes/figures/*.png"):
    img = Image.open(path).convert("RGB")
    img.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)
