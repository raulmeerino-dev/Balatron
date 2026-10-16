"""Package requested targeted native checks; never produces an IPA."""
from pathlib import Path
import sys, zipfile, re, subprocess
root=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,str(root/'tools/desktop_qa.py'),'--source','--modded','--layout','--width','393','--height','852'],check=True)
for kind in sys.argv[1:]:
 out=root/'qa'/(kind+'-final');out.mkdir(exist_ok=True)
 with zipfile.ZipFile(root/'qa/393x852-layout-smods/test.love') as src,zipfile.ZipFile(out/'test.love','w',zipfile.ZIP_DEFLATED) as dst:
  names=set(src.namelist())
  for item in src.infolist():
   data=src.read(item.filename)
   if item.filename=='qa_harness.lua':data=(root/'tests'/(kind+'_qa.lua')).read_bytes()
   if item.filename=='main.lua':data=data.replace(b'393x852-layout-smods',(kind+'-final').encode())
   dst.writestr(item.filename,data)
  # Require definitive art in native integration checks.
  ids=[]
  for registry in ('run_rules.lua','expansion.lua'):
   ids+=re.findall(r"id='([^']+)'",(root.parent/'MODS/Deck Mutations'/registry).read_text(encoding='utf-8'))
  prefix=next(n.split('/assets/')[0] for n in names if '/run_rules/discounts.png' in n)
  for id in ids:
   for scale in [1,2]:
    target=f'{prefix}/assets/{scale}x/run_rules/{id}.png'
    assert target in names, target
  print(kind,'all definitive modifier assets present')
 (out/'result.txt').write_text('')
