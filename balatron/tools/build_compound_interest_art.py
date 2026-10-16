"""Deterministic technical crop of the supplied art; no generated/repainted pixels."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT.parent / 'MODS' / 'Compound Interest'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, default=MOD / 'arte_original.png')
source = parser.parse_args().source.resolve()
if source != (MOD / 'arte_original.png').resolve():
    shutil.copyfile(source, MOD / 'arte_original.png')
im = Image.open(source).convert('RGBA')
# The cream frame, including its rounded corners. Preserve the aspect ratio.
frame_mask = Image.eval(im.getchannel('R'), lambda v: 255 if v > 210 else 0)
from PIL import ImageChops
frame_mask = ImageChops.multiply(frame_mask, Image.eval(im.getchannel('G'), lambda v: 255 if v > 195 else 0))
frame_mask = ImageChops.multiply(frame_mask, Image.eval(im.getchannel('B'), lambda v: 255 if v > 140 else 0))
box = frame_mask.getbbox()
assert box, 'Cream card frame not found in source'
crop = im.crop(box)
mask = Image.new('L', crop.size)
pixels, alpha = crop.load(), mask.load()
for y in range(crop.height):
    frame = [x for x in range(crop.width)
             if pixels[x, y][0] > 210 and pixels[x, y][1] > 195 and pixels[x, y][2] > 140]
    if frame:
        for x in range(min(frame), max(frame) + 1):
            alpha[x, y] = 255
crop.putalpha(mask)
outputs = {}
for scale in (1, 2):
    size = (71 * scale, 95 * scale)
    sprite = ImageOps.contain(crop, size, Image.Resampling.LANCZOS)
    result = Image.new('RGBA', size)
    result.alpha_composite(sprite, ((size[0]-sprite.width)//2, (size[1]-sprite.height)//2))
    target = MOD / 'assets' / f'{scale}x' / 'compound_interest.png'
    target.parent.mkdir(parents=True, exist_ok=True)
    result.save(target)
    outputs[str(scale)] = {'size': size, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
(MOD / 'art-manifest.json').write_text(json.dumps({
    'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'source_size': im.size,
    'crop': box, 'preserve_aspect': True, 'sprites': outputs
}, indent=2) + '\n')
print(json.dumps(outputs))
