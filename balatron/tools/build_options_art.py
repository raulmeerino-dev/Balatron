"""Pack the approved A/B/base artwork into native 71x95 Joker sprite frames."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / 'MODS' / 'Compound Interest'
frames = []
manifest = {'frame': [71, 95], 'order': ['A', 'B', 'base'], 'prompts': 'options-harlequin-prompts.json', 'sources': {}, 'sprites': {}}
for side in ('a', 'b', 'base'):
    path = ROOT / 'art-source' / f'options-{side}.png'
    with Image.open(path) as source:
        frame = source.convert('RGBA').resize((71, 95), Image.Resampling.NEAREST)
    # Native clipped corners. The card paper stays opaque and neutral white.
    for x, y in ((0, 0), (1, 0), (0, 1)):
        for px, py in ((x, y), (70-x, y), (x, 94-y), (70-x, 94-y)):
            r, g, b, _ = frame.getpixel((px, py))
            frame.putpixel((px, py), (r, g, b, 0))
    frames.append(frame)
    manifest['sources'][side] = hashlib.sha256(path.read_bytes()).hexdigest()
    for scale in (1, 2):
        out = ROOT / 'assets' / f'{scale}x' / f'options_{side}.png'
        frame.resize((71*scale, 95*scale), Image.Resampling.NEAREST).save(out)
for scale in (1, 2):
    atlas = Image.new('RGBA', (71*len(frames), 95))
    for i, frame in enumerate(frames):
        atlas.paste(frame, (71*i, 0))
    path = ROOT / 'assets' / f'{scale}x' / 'options.png'
    atlas.resize((71*len(frames)*scale, 95*scale), Image.Resampling.NEAREST).save(path)
    manifest['sprites'][str(scale)] = hashlib.sha256(path.read_bytes()).hexdigest()
(ROOT / 'art-source' / 'options-manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print('PASS: Options A/B/base individual frames and three-frame atlases at 1x / 2x')
