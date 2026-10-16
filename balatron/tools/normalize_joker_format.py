"""Conservative raster layout pass: preserve illustration pixels; unify card furniture.

No generated or redrawn illustrations. Original assets remain in art-source.
"""
from pathlib import Path
from collections import deque
import json, shutil
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
MODS=ROOT.parent/'MODS'
OUT=ROOT/'art-source/format-normalization'
PAPER=(241,241,235,255)
FAMILIES={'Compound Interest':(86,109,120),'RISK JOKERS':(180,20,35),
          'Joker Fusion':(174,125,40),'UPG JOKERS':(117,69,155)}
vanilla=Image.open(ROOT/'src/resources/textures/2x/Jokers.png').convert('RGBA')
glyph=vanilla.crop((12,12,26,102)).resize((12,76),Image.Resampling.NEAREST)
# Extract only the vanilla ink, not its white backing.
ink=Image.new('L',glyph.size)
for y in range(glyph.height):
    for x in range(glyph.width):
        r,g,b,a=glyph.getpixel((x,y))
        if a and max(r,g,b)<190: ink.putpixel((x,y),255)

def tile(im,colour,keep_dark=False):
    im=im.copy();pixels=im.load()
    # Paper connected to the border only: enclosed faces, hands and clothing
    # stay untouched, as do deliberate dark/coloured illustration backgrounds.
    q=deque();seen=set()
    for x in range(142): q.extend(((x,7),(x,182)))
    for y in range(190): q.extend(((7,y),(134,y)))
    while q:
        x,y=q.popleft()
        if (x,y) in seen or not (0<=x<142 and 0<=y<190):continue
        seen.add((x,y));r,g,b,a=pixels[x,y]
        if a>220 and min(r,g,b)>185 and max(r,g,b)-min(r,g,b)<45:
            pixels[x,y]=PAPER
            q.extend(((x-1,y),(x+1,y),(x,y-1),(x,y+1)))
    d=ImageDraw.Draw(im)
    # Keep the existing deliberate black card design of Compound Interest.
    if not keep_dark:
        d.rectangle((7,8,23,88),fill=PAPER)
        d.rectangle((119,101,135,181),fill=PAPER)
        letter=Image.new('RGBA',ink.size,colour+(255,))
        im.paste(letter,(8,10),ink)
        im.paste(letter.transpose(Image.Transpose.ROTATE_180),(122,104),ink.transpose(Image.Transpose.ROTATE_180))
    # Common two-pixel inset stroke and stepped corners, independent of family.
    d=ImageDraw.Draw(im)
    for box in [(0,0,141,5),(0,184,141,189),(0,0,5,189),(136,0,141,189)]:d.rectangle(box,fill=PAPER)
    d.line([(7,3),(134,3),(138,7),(138,182),(134,186),(7,186),(3,182),(3,7),(7,3)],fill=colour+(255,),width=2)
    alpha=Image.new('L',(142,190),255);ad=ImageDraw.Draw(alpha)
    for y,n in [(0,6),(1,4),(2,3),(3,2),(4,1),(5,1)]:
        ad.line((0,y,n-1,y),fill=0);ad.line((142-n,y,141,y),fill=0)
        ad.line((0,189-y,n-1,189-y),fill=0);ad.line((142-n,189-y,141,189-y),fill=0)
    im.putalpha(alpha)
    return im

records=[];tiles=[]
for mod,colour in FAMILIES.items():
    for path in sorted((MODS/mod/'assets/2x').glob('*.png')):
        # Special Doubles keep their A/B/neutral art, without lateral JOKER ink.
        if mod=='Compound Interest' and path.stem in {
            key+suffix for key in ('options','color_call','double_entry')
            for suffix in ('','_a','_b','_base')
        }:
            continue
        im=Image.open(path).convert('RGBA')
        if im.height!=190 or im.width%142:continue
        backup=OUT/'before'/mod/path.name;backup.parent.mkdir(parents=True,exist_ok=True)
        if not backup.exists():shutil.copy2(path,backup)
        im=Image.open(backup).convert('RGBA');result=Image.new('RGBA',im.size)
        for index in range(im.width//142):
            current=im.crop((index*142,0,(index+1)*142,190))
            corrected=tile(current,colour,path.stem=='compound_interest')
            result.paste(corrected,(index*142,0));tiles.append((path.stem+(' '+str(index+1) if im.width>142 else ''),corrected))
        result.save(path)
        result.resize((result.width//2,95),Image.Resampling.NEAREST).save(MODS/mod/'assets/1x'/path.name)
        records.append({'mod':mod,'asset':path.name,'size':im.size,'illustration':'preserved','changes':'connected paper, inset frame, corner mask, vanilla-derived side ink'})
for page in range((len(tiles)+11)//12):
    sheet=Image.new('RGB',(640,650),(30,40,40));d=ImageDraw.Draw(sheet)
    for i,(name,im) in enumerate(tiles[page*12:page*12+12]):
        x=i%4*160+9;y=i//4*215+4;sheet.paste(im,(x,y),im);d.text((x,y+192),name,fill='white')
    sheet.save(OUT/f'after-{page+1}.png')
(OUT/'manifest.json').write_text(json.dumps(records,indent=2)+'\n')
print(f'Normalized {len(records)} assets / {len(tiles)} frames, preserving illustration interiors')
