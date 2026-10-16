"""Bundle-ready iOS icons; no image library or Xcode dependency at build time."""
import json
from pathlib import Path
import re
import struct

CATALOG = Path(__file__).resolve().parents[1] / 'ios' / 'Assets.xcassets' / 'AppIcon.appiconset'


def png_chunks(data):
    offset = 8
    while offset + 12 <= len(data):
        length = struct.unpack('>I', data[offset:offset+4])[0]
        yield data[offset+4:offset+8]
        offset += length + 12


def load_icons():
    entries = json.loads((CATALOG / 'Contents.json').read_text(encoding='utf-8'))['images']
    icons, idioms = {}, {'iphone': [], 'ipad': []}
    for entry in entries:
        name = entry['filename']
        if Path(name).name != name or not name.endswith('.png') or name in icons:
            raise ValueError(f'Invalid or duplicate icon filename: {name}')
        data = (CATALOG / name).read_bytes()
        size = round(float(entry['size'].split('x')[0]) * int(entry['scale'][:-1]))
        if (data[:16] != b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR'
                or len(data) < 33
                or struct.unpack('>II', data[16:24]) != (size, size)
                or data[24:26] != b'\x08\x02' or b'tRNS' in png_chunks(data)):
            raise ValueError(f'Expected opaque 8-bit RGB {size}px PNG: {name}')
        icons[name] = data
        if entry['idiom'] in idioms:
            stem = re.split(r'@|~', name[:-4])[0]
            if stem not in idioms[entry['idiom']]:
                idioms[entry['idiom']].append(stem)
    if any(not names for names in idioms.values()):
        raise ValueError('Both iPhone and iPad icon sets are required')
    return icons, idioms


def old_icon_stems(plist):
    """Find filenames referenced by the shell, including any alternate icons."""
    stems = set()

    def visit(value):
        if not isinstance(value, dict):
            return
        for key, item in value.items():
            if key in ('CFBundleIconFile', 'CFBundleIconName', 'CFBundleIconFiles'):
                for name in item if isinstance(item, list) else [item]:
                    if isinstance(name, str):
                        stems.add(re.split(r'@|~', name.removesuffix('.png'))[0])
            elif isinstance(item, dict):
                visit(item)
    visit(plist)
    return stems


def apply_icon_plist(plist, idioms):
    # Loose PNG icons are supported by the prebuilt iOS shell. There is no
    # compiled AppIcon catalog here, so do not retain its CFBundleIconName.
    plist.pop('CFBundleIconFile', None)
    plist['CFBundleIconFiles'] = idioms['iphone']
    for key, idiom in [('CFBundleIcons', 'iphone'), ('CFBundleIcons~ipad', 'ipad')]:
        plist[key] = {'CFBundlePrimaryIcon': {
            'CFBundleIconFiles': idioms[idiom], 'UIPrerenderedIcon': False}}
