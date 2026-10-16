"""Pack the six mission Jokers; preserve existing class frames and pixel scaling."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageColor

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'balatron/art-source/mission-jokers'
ENTRIES = [
    ('RISK JOKERS', 'scorched_earth', 'loan_shark', 1),
    ('RISK JOKERS', 'powder_keg', 'loan_shark', 1),
    ('Compound Interest', 'graft', 'second_course', 1),
    ('Compound Interest', 'intermission', 'second_course', 1),
    ('UPG JOKERS', 'wayfinder', 'metamorphosis', 3),
    ('UPG JOKERS', 'orrery', 'metamorphosis', 3),
]

# Keep small semantic accents (blue planets, violet potion, green graft) even
# when they occupy too little area for frequency-based palette reduction.
COLOURS = '''
#101321 #24262c #45474d #69717b #9aa4ae #ced2d5
#f1f1eb #fff4db #dfd5bd #b6a586 #80735e
#07313b #004651 #12636a #25878b
#291d4b #46296d #683796 #944ac4 #bd7ae8 #e4c9ff
#073f8d #1263c4 #2299ef #68cdf6 #b1e8ff
#142f24 #22583c #38874a #66b849 #a0df6a
#531c2c #87242e #be282b #ed3b30 #ff7361
#744c28 #ad7228 #d59b31 #f5c640 #ffe78d
#983715 #d65b17 #f98c1c #ffb74c
'''.split()
PALETTE = Image.new('P', (1, 1))
rgb = [ImageColor.getrgb(c) for c in COLOURS]
PALETTE.putpalette([v for p in (rgb + [rgb[0]] * (256-len(rgb))) for v in p])

def build():
    preview = Image.new('RGB', (710, 440), '#182729')
    draw = ImageDraw.Draw(preview)
    manifest = []
    slot = 0
    for mod, key, reference, count in ENTRIES:
        folder = ROOT / 'MODS' / mod
        sources = []
        sprites = {}
        frame = Image.open(folder / 'assets/1x' / (reference + '.png')).convert('RGBA').crop((0, 0, 71, 95))
        atlas = Image.new('RGBA', (71 * count, 95))
        cards = []
        for index in range(count):
            name = key if count == 1 else f'{key}_{index + 1}'
            source = Image.open(ART / (name + '.png')).convert('RGBA')
            sources.append({'path': '../../balatron/art-source/mission-jokers/' + name + '.png',
                            'sha256': hashlib.sha256((ART / (name + '.png')).read_bytes()).hexdigest()})
            assert abs(source.width / source.height - 71 / 95) < .015, name
            assert source.getchannel('A').getextrema() == (255, 255), name
            card = source.convert('RGB').resize((71, 95), Image.Resampling.NEAREST)
            # Remove generated paper shading without smoothing sprite edges.
            card.putdata([(241, 241, 235) if min(p) > 230 and max(p)-min(p) < 25 else p
                          for p in card.getdata()])
            cards.append(card)
        # One restrained palette per evolutionary line prevents stage-to-stage
        # colour drift. No dithering: every native pixel remains a solid colour.
        for index, card in enumerate(cards):
            name = key if count == 1 else f'{key}_{index + 1}'
            card = card.quantize(palette=PALETTE, dither=Image.Dither.NONE).convert('RGBA')
            # Reuse the real class perimeter/corner mask, not a new frame design.
            for y in range(95):
                for x in range(71):
                    if x < 3 or x >= 68 or y < 3 or y >= 92:
                        card.putpixel((x, y), frame.getpixel((x, y)))
            # Exact existing family lettering; generated type must not compete
            # with the vanilla glyphs or overlap the illustration.
            for box in ((3, 4, 11, 44), (60, 51, 68, 91)):
                card.paste(frame.crop(box), box[:2])
            atlas.paste(card, (index * 71, 0))
            x, y = (slot % 5) * 142, (slot // 5) * 220
            enlarged = card.resize((142, 190), Image.Resampling.NEAREST)
            preview.paste(enlarged, (x, y), enlarged)
            draw.text((x + 3, y + 194), name, fill='white')
            slot += 1
        for scale in (1, 2):
            path = folder / f'assets/{scale}x/{key}.png'
            path.parent.mkdir(parents=True, exist_ok=True)
            atlas.resize((71 * count * scale, 95 * scale), Image.Resampling.NEAREST).save(path)
            manifest.append({'path': path.relative_to(ROOT).as_posix(), 'size': [71 * count * scale, 95 * scale],
                             'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
            sprites[str(scale)] = {'size': [71 * count * scale, 95 * scale],
                                   'sha256': manifest[-1]['sha256']}
        index_path = folder / 'art-manifest.json'
        entries = json.loads(index_path.read_text(encoding='utf-8')) if index_path.exists() else {}
        entries[key] = {'sources': sources, 'sprites': sprites, 'cell': [71, 95],
                        'family': {'RISK JOKERS': 'risk', 'UPG JOKERS': 'upg', 'Compound Interest': 'extra'}[mod],
                        'generator': 'built-in image_gen', 'side_text': True,
                        'prompts': '../../balatron/art-source/mission-jokers/prompts.json',
                        'sampling': 'nearest; shared fixed palette without dithering; exact 2x doubling',
                        'family_frame': reference, 'columns': list(range(count))}
        index_path.write_text(json.dumps(entries, indent=2) + '\n', encoding='utf-8')
    preview.save(ART / 'preview.png')
    (ART / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Packed {len(ENTRIES)} Jokers / {slot} frames / {len(manifest)} runtime assets')

if __name__ == '__main__':
    build()
