"""Build an isolated desktop harness; no test hooks enter the production IPA."""
import argparse
from pathlib import Path
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--width', type=int, default=390)
parser.add_argument('--height', type=int, default=844)
parser.add_argument('--top', type=int, default=47)
parser.add_argument('--bottom', type=int, default=34)
parser.add_argument('--resume', action='store_true')
parser.add_argument('--layout', action='store_true', help='Skip unrelated collection/menu scenarios')
parser.add_argument('--source', action='store_true', help='Use working Lua files for visual iteration')
parser.add_argument('--skin', action='store_true', help='Exercise Deck 1 in a separate save sandbox')
parser.add_argument('--modded', action='store_true', help='Run with real Lovely and bundled Steamodded')
parser.add_argument('--compound', action='store_true', help='Exercise Compound Interest in the real game')
parser.add_argument('--run-jokers', action='store_true', help='Exercise the five additional run Jokers')
parser.add_argument('--discovery', choices=('initial','buy','reopen'), help='Collection/profile persistence test phase')
parser.add_argument('--background', choices=('exercise','resume_off','resume_on'), help='Background rendering and settings persistence')
parser.add_argument('--dpi', type=int, default=1, help='Simulated canvas density (layout stays logical)')
parser.add_argument('--final-review', action='store_true', help='Directed custom-content and save/load release check')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / 'qa' / (f'{args.width}x{args.height}' + ('-resume' if args.resume else '-layout' if args.layout else '') + ('-deck1' if args.skin else '') + ('-smods' if args.modded else ''))
out.mkdir(parents=True, exist_ok=True)
if args.compound:
    out = out.parent / (out.name + '-compound')
    out.mkdir(parents=True, exist_ok=True)
if args.run_jokers:
    out = out.parent / (out.name + '-run-jokers')
    out.mkdir(parents=True, exist_ok=True)
if args.discovery:
    out = out.parent / (out.name + '-discovery-' + args.discovery)
    out.mkdir(parents=True, exist_ok=True)
if args.background:
    out = out.parent / (out.name + '-background-' + args.background)
    out.mkdir(parents=True, exist_ok=True)
config = (f"QA = {{background='{args.background or ''}', discovery='{args.discovery or ''}', w={args.width}, h={args.height}, top={args.top}, bottom={args.bottom}, "
          f"final_review={str(args.final_review).lower()}, dpi={args.dpi}, compound={str(args.compound).lower()}, modded={str(args.modded).lower()}, skin={str(args.skin).lower()}, resume={str(args.resume).lower()}, layout={str(args.layout).lower()}, out=[=[{out.as_posix()}]=]}}\n")
prefix = config + f"QA.run_jokers={str(args.run_jokers).lower()}\n" + """
love.system.getOS = function() return 'iOS' end
love.window.setFullscreen = function() return true end
local setMode = love.window.setMode
love.window.setMode = function(w, h, flags)
    flags = flags or {}; flags.fullscreen = false; flags.resizable = false
    return setMode(QA.w, QA.h, flags)
end
love.window.updateMode = love.window.setMode
love.window.getSafeArea = function() return 0, QA.top, QA.w, QA.h-QA.top-QA.bottom end
love.graphics.getDPIScale = function() return QA.dpi end
"""
working_mods = {}
if args.source and args.modded:
    import importlib.util
    import sys
    sys.path.insert(0, str(root))
    spec = importlib.util.spec_from_file_location('qa_build_inputs', root/'build.py')
    build_inputs = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(build_inputs)
    working_mods = {'install_mods/'+mod+'/'+path: data
                    for mod, files in build_inputs._bundled_mods().items()
                    for path, data in files.items()}
with zipfile.ZipFile(root / 'Game.love') as source, zipfile.ZipFile(out/'test.love', 'w', zipfile.ZIP_DEFLATED) as dest:
    for item in source.infolist():
        if working_mods and item.filename.startswith('install_mods/'):
            continue
        data = source.read(item.filename)
        if args.source and (item.filename.endswith('.lua') or item.filename.startswith('assets/')) and (root/'src'/item.filename).is_file():
            data = (root/'src'/item.filename).read_bytes()
            if item.filename.endswith('.lua'):
                data = data.replace(b'\r\n', b'\n')
        if item.filename == 'main.lua':
            data = prefix.encode() + data + b'\nrequire "qa_harness"\n'
        if item.filename == 'conf.lua':
            data += ("\nlocal conf = love.conf\nfunction love.conf(t)\n conf(t)\n"
                     f" t.identity = '{'game' if args.modded else 'portrait-qa-'+str(args.width)+'x'+str(args.height)+('-deck1' if args.skin else '')}'\n"
                     f" t.window.width={args.width}; t.window.height={args.height}\n"
                     " t.window.fullscreen=false; t.console=false\nend\n").encode()
        dest.writestr(item.filename, data)
    for path, data in working_mods.items():
        dest.writestr(path, data)
    if args.source:
        present=set(dest.namelist())
        for path in (root/'src').rglob('*'):
            if path.is_file() and (path.suffix=='.lua' or 'assets' in path.relative_to(root/'src').parts) and path.relative_to(root/'src').as_posix() not in present:
                dest.writestr(path.relative_to(root/'src').as_posix(),path.read_bytes())
    dest.writestr('qa_harness.lua', (root/'tests/desktop_qa.lua').read_bytes())
    dest.writestr('compound_interest_qa.lua', (root/'tests/compound_interest_qa.lua').read_bytes())
    dest.writestr('run_jokers_qa.lua', (root/'tests/run_jokers_qa.lua').read_bytes())
    dest.writestr('compound_discovery_qa.lua', (root/'tests/compound_discovery_qa.lua').read_bytes())
    dest.writestr('background_qa.lua', (root/'tests/background_qa.lua').read_bytes())
print(out/'test.love')
