"""Verify the path hotfix's scope, installed files and real desktop boot results."""
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root))
import build

def game_archive(ipa):
    with zipfile.ZipFile(ipa) as z:
        return z.read(build._ios_app_dir(z) + '/game.love')

old_path = root.parent / 'balatron-v6.ipa'
new_path = root / 'balatron.ipa'
with zipfile.ZipFile(io.BytesIO(game_archive(old_path))) as old, zipfile.ZipFile(io.BytesIO(game_archive(new_path))) as new:
    assert set(old.namelist()) == set(new.namelist())
    changed = [p for p in old.namelist() if old.read(p) != new.read(p)]
    assert set(changed) == {'portrait_mods.lua', 'portrait_config.lua'}, changed
    assert old.read('portrait_config.lua').replace(b'ios-portrait-6-background-cycle', b'ios-portrait-7-ios-mod-path') == new.read('portrait_config.lua')
    assert new.read('portrait_mods.lua') == (root / 'src/portrait_mods.lua').read_bytes().replace(b'\r\n', b'\n')

with zipfile.ZipFile(old_path) as old, zipfile.ZipFile(new_path) as new:
    assert set(old.namelist()) == set(new.namelist())
    changed_bundle = [p for p in old.namelist() if old.read(p) != new.read(p)]
    assert changed_bundle == [build._ios_app_dir(new) + '/game.love'], changed_bundle

installed = root / 'qa/pathfix-v7/LOVE/game/Mods'
count = 0
for mod, files in build._bundled_mods().items():
    for path, contents in files.items():
        assert (installed/mod/path).read_bytes() == contents, (mod,path)
        count += 1

phases = {}
for phase in ('initial','buy','reopen'):
    path = root / f'qa/390x844-smods-discovery-{phase}/result.txt'
    log = path.read_text(encoding='utf-8')
    assert 'qa/pathfix-v7/LOVE/game' in log
    assert 'FAIL:' not in log and log.rstrip().endswith('PASS: discovery_persisted'), phase
    phases[phase] = log.splitlines()

report = {'status':'PASS', 'device_validation':'pending after reported iPhone regression',
          'runtime':'actual desktop LOVE 11.5 / Lovely 0.10.0 / Steamodded beta-1224a',
          'changed_game_files':changed, 'changed_bundle_files':changed_bundle,
          'installed_files_byte_verified':count, 'phases':phases,
          'ios_alias_test':'tests/portrait_mods_test.lua',
          'ipa_bytes':new_path.stat().st_size,
          'ipa_sha256':hashlib.sha256(new_path.read_bytes()).hexdigest()}
output = root / 'validation-output/pathfix-report-v7.json'
output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(f'PASS: only installer + revision changed; {count} installed files verified; 3 independent boot processes')
print(report['ipa_sha256'])
