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
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / 'qa' / (f'{args.width}x{args.height}' + ('-resume' if args.resume else ''))
out.mkdir(parents=True, exist_ok=True)
config = (f"QA = {{w={args.width}, h={args.height}, top={args.top}, bottom={args.bottom}, "
          f"resume={str(args.resume).lower()}, out=[=[{out.as_posix()}]=]}}\n")
prefix = config + """
love.system.getOS = function() return 'iOS' end
love.window.setFullscreen = function() return true end
local setMode = love.window.setMode
love.window.setMode = function(w, h, flags)
    flags = flags or {}; flags.fullscreen = false; flags.resizable = false
    return setMode(QA.w, QA.h, flags)
end
love.window.updateMode = love.window.setMode
love.window.getSafeArea = function() return 0, QA.top, QA.w, QA.h-QA.top-QA.bottom end
"""
with zipfile.ZipFile(root / 'Game.love') as source, zipfile.ZipFile(out/'test.love', 'w', zipfile.ZIP_DEFLATED) as dest:
    for item in source.infolist():
        data = source.read(item.filename)
        if item.filename == 'main.lua':
            data = prefix.encode() + data + b'\nrequire "qa_harness"\n'
        if item.filename == 'conf.lua':
            data += ("\nlocal conf = love.conf\nfunction love.conf(t)\n conf(t)\n"
                     f" t.identity = 'portrait-qa-{args.width}x{args.height}'\n"
                     f" t.window.width={args.width}; t.window.height={args.height}\n"
                     " t.window.fullscreen=false; t.console=false\nend\n").encode()
        dest.writestr(item.filename, data)
    dest.writestr('qa_harness.lua', (root/'tests/desktop_qa.lua').read_bytes())
print(out/'test.love')
