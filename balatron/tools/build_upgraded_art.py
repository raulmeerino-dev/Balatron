"""Pack supplied Metamorphosis art without repainting or stretching the originals."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageChops, ImageOps

MOD = Path(__file__).resolve().parents[2] / 'MODS' / 'UPG JOKERS'
sources = ('LARVA.png', 'CHRYSALID.png', 'MOTH.png')
atlases = {s: Image.new('RGBA', (213*s, 95*s)) for s in (1, 2)}
manifest = {}
for index, name in enumerate(sources):
    source = MOD / 'METAMORPHOSIS' / name
    im = Image.open(source).convert('RGBA')
    cream = ImageChops.multiply(
        Image.eval(im.getchannel('R'), lambda v: 255 if v > 210 else 0),
        Image.eval(im.getchannel('G'), lambda v: 255 if v > 195 else 0))
    cream = ImageChops.multiply(cream, Image.eval(im.getchannel('B'), lambda v: 255 if v > 140 else 0))
    box = cream.getbbox()
    assert box, f'Missing card frame: {source}'
    crop, frame = im.crop(box), cream.crop(box)
    mask = Image.new('L', crop.size)
    for y in range(crop.height):
        row = [x for x in range(crop.width) if frame.getpixel((x, y))]
        if row:
            for x in range(min(row), max(row)+1):
                mask.putpixel((x, y), 255)
    crop.putalpha(mask)
    for scale, atlas in atlases.items():
        sprite = ImageOps.contain(crop, (71*scale, 95*scale), Image.Resampling.LANCZOS)
        atlas.alpha_composite(sprite, (index*71*scale+(71*scale-sprite.width)//2, (95*scale-sprite.height)//2))
    manifest[name] = {'sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'crop': box, 'column': index}
for scale, atlas in atlases.items():
    path = MOD / 'assets' / f'{scale}x' / 'metamorphosis.png'
    path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(path)
(MOD/'art-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
print('Metamorphosis: 213x95 and 426x190 RGBA; Larva / Chrysalis / Moth. Originals unchanged.')
