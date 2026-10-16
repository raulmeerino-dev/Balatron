"""Normalize a reviewed individual-card deck and build the existing 4x skin atlases."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageOps
from build_card_skin import SIZE, SUITS, RANKS, ATLAS_RANKS, overlay

ROOT = Path(__file__).resolve().parents[1]


def normalize(path):
    source = Image.open(path).convert('RGBA')
    pixels = np.asarray(source)
    light = pixels[:, :, :3].min(axis=2) > 140
    # Remove only the dark exterior outside the continuous cream card silhouette.
    alpha = np.zeros(light.shape, dtype=np.uint8)
    for y, row in enumerate(light):
        xx = np.flatnonzero(row)
        if len(xx):
            alpha[y, xx[0]:xx[-1]+1] = 255
    source.putalpha(Image.fromarray(alpha))
    paper = tuple(np.median(pixels[:, :, :3][light], axis=0).astype(int))
    card = Image.new('RGBA', SIZE, paper + (255,))
    # Preserve the original aspect ratio, including every Ace/index; never stretch.
    fitted = ImageOps.contain(source, (SIZE[0]-8, SIZE[1]-8), Image.Resampling.NEAREST)
    card.alpha_composite(fitted, ((SIZE[0]-fitted.width)//2, (SIZE[1]-fitted.height)//2))
    mask = Image.new('L', SIZE)
    ImageDraw.Draw(mask).rounded_rectangle((2, 2, SIZE[0]-3, SIZE[1]-3), radius=14, fill=255)
    card.putalpha(mask)
    return card


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('deck', type=Path)
    parser.add_argument('--skin', required=True, choices=['deck_occult_arcade', 'deck3_retro_gaming'])
    args = parser.parse_args()
    source, final, atlas_dir = (args.deck / part for part in ('source', 'final', 'atlas'))
    names = [f'{suit}_{rank}.png' for suit in SUITS for rank in RANKS] + ['back.png']
    missing = [name for name in names if not (source/name).is_file()]
    if missing:
        raise SystemExit('Missing source cards: ' + ', '.join(missing))
    for path in (final, atlas_dir):
        path.mkdir(parents=True, exist_ok=True)
    fronts = Image.new('RGBA', (SIZE[0]*13, SIZE[1]*4))
    enhanced = Image.new('RGBA', fronts.size)
    manifest = {'skin': args.skin, 'cell': SIZE, 'logical_cell': [71, 95], 'dpi': 4,
                'paper_shader': 'assets/skins/neutral_paper.fs', 'cards': {}}
    contact = Image.new('RGB', (13*148, 5*210), '#252525')
    draw = ImageDraw.Draw(contact)
    for i, name in enumerate(names):
        # Previously reviewed cards are authoritative; assembling a new atlas
        # must not redo their index corrections or normalization.
        card = Image.open(final/name).convert('RGBA') if (final/name).is_file() else normalize(source/name)
        if card.size != SIZE:
            raise ValueError(f'{final/name}: expected reviewed cell size {SIZE}')
        card.save(final/name, optimize=True)
        info = {'source_sha256': hashlib.sha256((source/name).read_bytes()).hexdigest(),
                'final_sha256': hashlib.sha256((final/name).read_bytes()).hexdigest()}
        if name != 'back.png':
            suit, rank = Path(name).stem.split('_')
            col, row = ATLAS_RANKS.index(rank), list(SUITS).index(suit)
            pos = (col*SIZE[0], row*SIZE[1])
            fronts.paste(card, pos)
            enhanced.paste(overlay(card), pos)
            info['atlas_cell'] = [col, row]
        else:
            card.save(atlas_dir/name, optimize=True)
        manifest['cards'][name] = info
        thumb = card.resize((142, 190), Image.Resampling.NEAREST)
        x, y = i % 13 * 148, i // 13 * 210
        contact.paste(thumb, (x+3, y), thumb)
        draw.text((x+3, y+192), name, fill='white')
    fronts.save(atlas_dir/'fronts.png', optimize=True)
    enhanced.save(atlas_dir/'enhanced.png', optimize=True)
    contact.save(args.deck/'contact-sheet.png')
    (args.deck/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    runtime = ROOT/'src/assets/skins'/args.skin
    runtime.mkdir(parents=True, exist_ok=True)
    for name in ('fronts.png', 'enhanced.png', 'back.png'):
        shutil.copy2(atlas_dir/name, runtime/name)
    print(f'{args.skin}: 52 faces + back; cell {SIZE}, atlas {fronts.size}')


if __name__ == '__main__':
    main()
