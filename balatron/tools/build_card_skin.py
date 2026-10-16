"""Extract the final DECK1 sheets without guessing crop coordinates.

Requires Pillow and numpy. Original sheets are read only. No generated art.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SIZE = (284, 380)  # 4x the engine's 71 x 95 logical sprite cell.
SUITS = {'hearts': 'CORAZON', 'clubs': 'TREBOL', 'diamonds': 'ROMBOS', 'spades': 'PICAS'}
RANKS = ['A'] + [str(n) for n in range(2, 11)] + ['J', 'Q', 'K']
ATLAS_RANKS = RANKS[1:] + ['A']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def runs(mask):
    edges = np.diff(np.r_[False, mask, False].astype(np.int8))
    return list(zip(np.flatnonzero(edges == 1), np.flatnonzero(edges == -1)))


def detect_cards(image, expected):
    # All supplied sheets have a dark exterior and a continuous light border.
    # Project that border onto rows/columns; illustrations inside may be black.
    pixels = np.asarray(image.convert('RGB'))
    light = pixels.min(axis=2) > 140
    rows = [(a, b) for a, b in runs(light.sum(axis=1) > 12) if b-a > 80]
    boxes = []
    for top, bottom in rows:
        for left, right in runs(light[top:bottom].sum(axis=0) > 12):
            if right-left < 80:
                continue
            yy, xx = np.nonzero(light[top:bottom, left:right])
            boxes.append((int(left+xx.min()), int(top+yy.min()),
                          int(left+xx.max()+1), int(top+yy.max()+1)))
    if len(boxes) != expected:
        raise ValueError(f'Expected {expected} card borders, detected {len(boxes)}: {boxes}')
    if any(not .55 < (r-l)/(b-t) < .85 for l, t, r, b in boxes):
        raise ValueError('Unexpected card aspect ratio; inspect source sheet')
    return boxes


def normalize(image, box):
    crop = image.crop(box).convert('RGBA')
    pixels = np.asarray(crop)
    light = pixels[:, :, :3].min(axis=2) > 140
    mask = np.zeros(light.shape, dtype=np.uint8)
    # Fill between the left/right cream edges; retain all dark interior art.
    for y, row in enumerate(light):
        x = np.flatnonzero(row)
        if len(x):
            mask[y, x[0]:x[-1]+1] = 255
    crop.putalpha(Image.fromarray(mask))
    paper = np.median(pixels[:, :, :3][light], axis=0).astype(int)
    canvas = Image.new('RGBA', SIZE, tuple(paper) + (255,))
    fitted = ImageOps.contain(crop, (SIZE[0]-8, SIZE[1]-8), Image.Resampling.LANCZOS)
    canvas.alpha_composite(fitted, ((SIZE[0]-fitted.width)//2, (SIZE[1]-fitted.height)//2))
    # Same rounded silhouette for every card; only outside padding is removed.
    mask = Image.new('L', (SIZE[0]*4, SIZE[1]*4))
    ImageDraw.Draw(mask).rounded_rectangle((8, 8, SIZE[0]*4-9, SIZE[1]*4-9), radius=56, fill=255)
    canvas.putalpha(mask.resize(SIZE, Image.Resampling.LANCZOS))
    return canvas


def overlay(image):
    # Enhanced cards keep Balatro's own gold/steel/glass/etc. substrate visible.
    pixels = np.array(image)
    ink = np.clip((220 - pixels[:, :, :2].min(axis=2).astype(float))/45, 0, 1)
    pixels[:, :, 3] = np.rint(pixels[:, :, 3] * ink).astype(np.uint8)
    return Image.fromarray(pixels)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, default=ROOT.parent/'DECK1')
    parser.add_argument('--skin', default='deck1')
    args = parser.parse_args()
    if not re.fullmatch('[a-z0-9_-]+', args.skin):
        raise ValueError('Skin ID must contain only lowercase letters, digits, underscore or hyphen')
    output = ROOT/'assets/skins'/args.skin
    cards_dir = output/'cards'
    runtime = ROOT/'src/assets/skins'/args.skin
    cards_dir.mkdir(parents=True, exist_ok=True)
    runtime.mkdir(parents=True, exist_ok=True)
    atlas = Image.new('RGBA', (SIZE[0]*13, SIZE[1]*4))
    ink_atlas = Image.new('RGBA', atlas.size)
    report = {'skin': args.skin, 'card_size': SIZE, 'atlas_size': atlas.size,
              'logical_cell': [71, 95], 'dpi_scale': 4, 'sources': {}, 'cards': {}}
    previews = []
    for row, (suit, folder) in enumerate(SUITS.items()):
        paths = sorted((args.source/folder).glob('*.png'))
        if len(paths) != 1:
            raise ValueError(f'{folder}: supply exactly one final PNG, found {len(paths)}')
        source = paths[0]
        sheet = Image.open(source).convert('RGB')
        boxes = detect_cards(sheet, 13)
        report['sources'][suit] = {'file': str(source.relative_to(args.source)), 'sha256': sha(source)}
        for rank, box in zip(RANKS, boxes):
            name = f'{suit}_{rank}.png'
            card = normalize(sheet, box)
            correction = output/'corrections'/name
            if correction.is_file():
                edited = Image.open(correction).convert('RGBA')
                background = Image.new('RGBA', edited.size, (25, 25, 25, 255))
                background.alpha_composite(edited)
                corrected_box = detect_cards(background, 1)[0]
                card = normalize(background, corrected_box)
            # Normalized court art is authoritative over the original sheets.
            face_override = output/'face_overrides'/name
            if rank in ('J', 'Q', 'K') and face_override.is_file():
                card = Image.open(face_override).convert('RGBA')
                if card.size != SIZE:
                    raise ValueError(f'{face_override}: expected normalized size {SIZE}')
            card.save(cards_dir/name, optimize=True)
            pos = (ATLAS_RANKS.index(rank)*SIZE[0], row*SIZE[1])
            atlas.paste(card, pos)
            ink_atlas.paste(overlay(card), pos)
            report['cards'][name] = {'crop': box, 'atlas_cell': [ATLAS_RANKS.index(rank), row],
                                     'sha256': sha(cards_dir/name)}
            if correction.is_file():
                report['cards'][name]['approved_correction'] = str(correction.relative_to(output))
                report['cards'][name]['correction_sha256'] = sha(correction)
            if rank in ('J', 'Q', 'K') and face_override.is_file():
                report['cards'][name]['face_override'] = str(face_override.relative_to(output))
                report['cards'][name]['face_override_sha256'] = sha(face_override)
            previews.append((name, card.copy()))
    paths = sorted((args.source/'REVERSO').glob('*.png'))
    if len(paths) != 1:
        raise ValueError('REVERSO must contain exactly one final PNG')
    sheet = Image.open(paths[0]).convert('RGB')
    box = detect_cards(sheet, 1)[0]
    back = normalize(sheet, box)
    back.save(cards_dir/'back.png', optimize=True)
    back.save(runtime/'back.png', optimize=True)
    report['sources']['back'] = {'file': str(paths[0].relative_to(args.source)), 'sha256': sha(paths[0])}
    report['cards']['back.png'] = {'crop': box, 'sha256': sha(cards_dir/'back.png')}
    atlas.save(runtime/'fronts.png', optimize=True)
    ink_atlas.save(runtime/'enhanced.png', optimize=True)
    (output/'manifest.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    contact = Image.new('RGB', (13*148, 4*214+218), '#252525')
    draw = ImageDraw.Draw(contact)
    for index, (name, card) in enumerate(previews + [('back.png', back)]):
        x, y = index % 13 * 148, index // 13 * 214
        thumb = card.resize((142, 190), Image.Resampling.LANCZOS)
        contact.paste(thumb, (x+3, y), thumb)
        draw.text((x+4, y+193), name, fill='white')
    contact.save(output/'contact-sheet.png')
    print(f'Processed 52 cards + back; {SIZE}; atlas {atlas.size}; sources hashed in {output}')


if __name__ == '__main__':
    main()
