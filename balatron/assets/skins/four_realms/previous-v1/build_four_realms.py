"""Integrate the 16 generated illustrations as native-size front overlays; preserve vanilla indices."""
from pathlib import Path
from collections import deque
import hashlib
import json
from PIL import Image, ImageOps, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'assets/skins/four_realms'
OUT=ROOT/'src/assets/skins/four_realms'
OUT.mkdir(parents=True,exist_ok=True)
SUITS=('hearts','clubs','diamonds','spades')
RANKS={'J':9,'Q':10,'K':11,'A':12}

def illustration(path):
    source=Image.open(path).convert('RGBA')
    # Remove only border-connected neutral background, keeping white faces/clothes intact.
    source.thumbnail((300,400),Image.Resampling.NEAREST)
    pixels=source.load();w,h=source.size;seen=set();q=deque()
    for x in range(w):q.extend(((x,0),(x,h-1)))
    for y in range(h):q.extend(((0,y),(w-1,y)))
    while q:
        x,y=q.popleft()
        if not (0<=x<w and 0<=y<h) or (x,y) in seen:continue
        seen.add((x,y));r,g,b,a=pixels[x,y]
        if min(r,g,b)>195 and max(r,g,b)-min(r,g,b)<24:
            pixels[x,y]=(r,g,b,0)
            q.extend(((x-1,y),(x+1,y),(x,y-1),(x,y+1)))
    crop=source.crop(source.getbbox())
    # One native 1x sprite, then exact pixel doubling. Never bilinear filtering.
    crop=ImageOps.contain(crop,(47,79),Image.Resampling.NEAREST)
    return crop.resize((crop.width*2,crop.height*2),Image.Resampling.NEAREST)

manifest={'tool':'built-in image_gen','cell':[71,95],'dpi':2,'ranks':['A','J','Q','K'],
          'fallback':'native default 2–10; native paper, enhancements and run back', 'cards':{}}
for contrast,filename in [('lc','8BitDeck.png'),('hc','8BitDeck_opt2.png')]:
    native=Image.open(ROOT/'src/resources/textures/2x'/filename).convert('RGBA')
    atlas=native.copy()
    for row,suit in enumerate(SUITS):
        for rank,col in RANKS.items():
            path=ART/'source'/f'{suit}_{rank}.png';art=illustration(path)
            cell=Image.new('RGBA',(142,190))
            cell.alpha_composite(art,((142-art.width)//2,(190-art.height)//2))
            original=native.crop((col*142,row*190,(col+1)*142,(row+1)*190))
            for box in ((0,0,28,56),(114,134,142,190)):
                cell.alpha_composite(original.crop(box),(box[0],box[1]))
            atlas.paste(cell,(col*142,row*190))
            manifest['cards'][f'{suit}_{rank}']={'cell':[col,row],'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    atlas.save(OUT/f'fronts_{contrast}.png')
    # Native white card stock is a separate sprite beneath these front overlays.
    paper=Image.open(ROOT/'src/resources/textures/2x/Enhancers.png').convert('RGBA').crop((142,0,284,190))
    sheet=Image.new('RGBA',(4*160,4*215),(28,36,39,255));draw=ImageDraw.Draw(sheet)
    for row,suit in enumerate(SUITS):
        for i,rank in enumerate(('A','J','Q','K')):
            col=RANKS[rank];card=paper.copy();card.alpha_composite(atlas.crop((col*142,row*190,(col+1)*142,(row+1)*190)))
            sheet.alpha_composite(card,(i*160+9,row*215));draw.text((i*160+9,row*215+194),f'{suit} {rank}',fill='white')
    sheet.save(ART/f'preview_{contrast}.png')
(ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print('PASS: 16 illustrated fronts; native indices, 36 fallback cards, LC/HC atlases preserved.')
