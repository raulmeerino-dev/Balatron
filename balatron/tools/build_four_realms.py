"""Integrate the 16 generated illustrations as native-size front overlays; preserve vanilla indices."""
from pathlib import Path
import argparse
import hashlib
import json
from PIL import Image, ImageOps, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--variant',choices=('four_realms','four_realms_v2','velvet_catastrophe','dream_circuit','carnival_relics'),default='four_realms')
variant=parser.parse_args().variant
ART=ROOT/'assets/skins'/variant
OUT=ROOT/'src/assets/skins'/variant
OUT.mkdir(parents=True,exist_ok=True)
SUITS=('hearts','clubs','diamonds','spades')
RANKS={'J':9,'Q':10,'K':11,'A':12}

def illustration(path):
    source=Image.open(path).convert('RGBA')
    # Generated cutouts carry real alpha: never erase pale faces, metal or cloth.
    alpha=source.getchannel('A')
    if alpha.getextrema()[0] != 0 or not alpha.getbbox():
        raise ValueError(f'{path}: expected a nonempty transparent cutout')
    source.putalpha(alpha.point(lambda a: 255 if a >= 128 else 0))
    crop=source.crop(source.getbbox())
    # Compose on the native grid before doubling, including the placement offset.
    return ImageOps.contain(crop,(47,79),Image.Resampling.NEAREST)

manifest={'tool':'built-in image_gen','revision':2,'cell':[71,95],'dpi':2,'ranks':['A','J','Q','K'],
          'variant':variant,
          'sampling':'nearest; native-grid placement; binary alpha; no mipmaps',
          'fallback':'native default 2–10; native paper, enhancements and run back', 'cards':{}}
for contrast,filename in [('lc','8BitDeck.png'),('hc','8BitDeck_opt2.png')]:
    native=Image.open(ROOT/'src/resources/textures/2x'/filename).convert('RGBA')
    atlas=native.copy()
    for row,suit in enumerate(SUITS):
        for rank,col in RANKS.items():
            path=ART/'source'/f'{suit}_{rank}.png';art=illustration(path)
            logical=Image.new('RGBA',(71,95))
            logical.alpha_composite(art,((71-art.width)//2,(95-art.height)//2))
            cell=logical.resize((142,190),Image.Resampling.NEAREST)
            original=native.crop((col*142,row*190,(col+1)*142,(row+1)*190))
            for box in ((0,0,28,56),(114,134,142,190)):
                # Reserve the entire vanilla index rectangle, including its whitespace.
                cell.paste(original.crop(box),(box[0],box[1]))
            atlas.paste(cell,(col*142,row*190))
            manifest['cards'][f'{suit}_{rank}']={'cell':[col,row],'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    atlas.save(OUT/f'fronts_{contrast}.png')
    # Native white card stock is a separate sprite beneath these front overlays.
    paper=Image.open(ROOT/'src/resources/textures/2x/Enhancers.png').convert('RGBA').crop((142,0,284,190))
    sheet=Image.new('RGBA',(4*160,4*215),(28,36,39,255));draw=ImageDraw.Draw(sheet)
    for row,suit in enumerate(SUITS):
        for i,rank in enumerate(('A','J','Q','K')):
            col=RANKS[rank];card=paper.copy();card.alpha_composite(atlas.crop((col*142,row*190,(col+1)*142,(row+1)*190)))
            if variant in ('velvet_catastrophe','dream_circuit','carnival_relics') and contrast == 'lc':
                (ART/'cards').mkdir(exist_ok=True)
                card.save(ART/'cards'/f'{suit}_{rank}.png')
            sheet.alpha_composite(card,(i*160+9,row*215));draw.text((i*160+9,row*215+194),f'{suit} {rank}',fill='white')
    sheet.save(ART/f'preview_{contrast}.png')
    if contrast == 'lc':
        sheet.save(ART/'source-preview.png')
(ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print('PASS: 16 illustrated fronts; native indices, 36 fallback cards, LC/HC atlases preserved.')
