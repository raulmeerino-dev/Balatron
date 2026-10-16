"""Import six finished Doubles cards, with native geometry and exact 2x doubling."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageOps

ROOT=Path(__file__).resolve().parents[2]
MOD=ROOT/'MODS/Compound Interest'
ART=MOD/'art-source/doubles'
FRAME=(71,95)
# Register finished cards to the established Options perimeter and safe area.
# Only the existing outer frame is retained; no character extraction/compositing.
family_frame=Image.open(MOD/'assets/1x/options_base.png').convert('RGBA')
family_frame.putalpha(255)
ImageDraw.Draw(family_frame).rectangle((4,3,66,91),fill=(254,254,254,255))
manifest={'tool':'built-in image_gen','frame':FRAME,'order':['A','B','neutral'],
          'sampling':'complete opaque card; nearest; 32 flat colours without dithering; exact 2x doubling',
          'family_frame':'Options perimeter; opaque white corners; inner safe area 4,4,67,91',
          'prompts':'prompts.json','cards':{}}
preview=Image.new('RGBA',(3*158,2*218),(30,37,42,255))
draw=ImageDraw.Draw(preview)
for row,key in enumerate(('color_call','double_entry')):
    atlas=Image.new('RGBA',(FRAME[0]*3,FRAME[1]))
    sources={}
    for col,state in enumerate(('a','b','base')):
        path=ART/f'{key}_{state}.png'
        art=Image.open(path).convert('RGBA')
        # Sources include paper, background, border and illustration. Register
        # their full opaque interior, without cutting out a character. Drop only
        # the generated outer perimeter so the six cards share the exact family
        # frame instead of six slightly different AI-rendered outlines.
        assert art.getchannel('A').getextrema()==(255,255), path
        assert abs(art.width/art.height-71/95)<0.01, path
        card=family_frame.copy()
        inset=round(art.width*0.015)
        interior=art.crop((inset,inset,art.width-inset,art.height-inset))
        interior=ImageOps.contain(interior,(63,87),Image.Resampling.NEAREST)
        interior=interior.convert('RGB')
        interior.putdata([(254,254,254) if min(p)>230 and max(p)-min(p)<25 else p
                          for p in interior.getdata()])
        interior=interior.quantize(colors=32,dither=Image.Dither.NONE).convert('RGBA')
        card.paste(interior,(4+(63-interior.width)//2,4+(87-interior.height)//2))
        atlas.paste(card,(col*71,0))
        for scale in (1,2):
            card.resize((71*scale,95*scale),Image.Resampling.NEAREST).save(MOD/f'assets/{scale}x/{key}_{state}.png')
        # Display neutral first, then A/B, while retaining Options atlas order.
        display_col={'base':0,'a':1,'b':2}[state]
        preview.alpha_composite(card.resize((142,190),Image.Resampling.NEAREST),(display_col*158+8,row*218+4))
        names={'color_call':{'base':'Neutral','a':'Rojo','b':'Negro'},
               'double_entry':{'base':'Neutral','a':'Debito','b':'Credito'}}
        draw.text((display_col*158+8,row*218+198),names[key][state],fill='white')
        sources[state]=hashlib.sha256(path.read_bytes()).hexdigest()
    sprites={}
    for scale in (1,2):
        out=MOD/f'assets/{scale}x/{key}.png'
        atlas.resize((213*scale,95*scale),Image.Resampling.NEAREST).save(out)
        sprites[str(scale)]=hashlib.sha256(out.read_bytes()).hexdigest()
    manifest['cards'][key]={'sources':sources,'sprites':sprites}
(ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
index_path=MOD/'art-manifest.json'
index=json.loads(index_path.read_text(encoding='utf-8'))
for key,data in manifest['cards'].items():
    index[key]={'manifest':'art-source/doubles/manifest.json','prompts':'art-source/doubles/prompts.json',
                'family':'doubles','side_text':False,'frame':FRAME,'order':manifest['order'],
                'sprites':{str(scale):{'size':[213*scale,95*scale],'sha256':data['sprites'][str(scale)]} for scale in (1,2)}}
index_path.write_text(json.dumps(index,indent=2)+'\n',encoding='utf-8')
preview.save(ART/'preview.png')
print('PASS: six sprites and two A/B/neutral atlases, 1x/2x.')
