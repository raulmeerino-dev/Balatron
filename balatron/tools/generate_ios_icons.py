"""Regenerate the committed iOS PNG set from the opaque square master (Pillow)."""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'ios' / 'Assets.xcassets' / 'AppIcon.appiconset'


def main():
    with Image.open(ROOT / 'ios' / 'icon-master.png') as image:
        if image.width != image.height:
            raise ValueError('Icon master must be square')
        master = image.convert('RGB')
    CATALOG.mkdir(parents=True, exist_ok=True)
    entries = []
    specs = {
        'iphone': [(20, (2, 3)), (29, (2, 3)), (40, (2, 3)), (60, (2, 3))],
        'ipad': [(20, (1, 2)), (29, (1, 2)), (40, (1, 2)),
                 (76, (1, 2)), (83.5, (2,))],
        'ios-marketing': [(1024, (1,))],
    }
    for idiom, slots in specs.items():
        for points, scales in slots:
            for scale in scales:
                size = f'{points}x{points}'
                suffix = '~ipad' if idiom == 'ipad' else ''
                density = f'@{scale}x' if scale > 1 else ''
                filename = f'PortraitIcon{size}{density}{suffix}.png'
                pixels = round(points * scale)
                master.resize((pixels, pixels), Image.Resampling.LANCZOS).save(
                    CATALOG / filename, optimize=True)
                entries.append(dict(idiom=idiom, size=size, scale=f'{scale}x', filename=filename))
    info = {'info': {'author': 'xcode', 'version': 1}}
    (CATALOG / 'Contents.json').write_text(
        json.dumps({'images': entries, **info}, indent=2) + '\n', encoding='utf-8')
    (CATALOG.parent / 'Contents.json').write_text(
        json.dumps(info, indent=2) + '\n', encoding='utf-8')
    print(f'Generated {len(entries)} opaque RGB icons in {CATALOG}')


if __name__ == '__main__':
    main()
