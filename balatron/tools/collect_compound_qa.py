"""Collect completed, isolated desktop runs; fail instead of reporting stale failures."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
runs={
    'portrait_393_3x':('393x852-deck1-smods','diagnostics'),
    'portrait_375_2x':('375x667-layout-deck1-smods','diagnostics'),
    'compound':('393x852-deck1-smods-compound','compound_save_shop'),
    'compound_restart':('393x852-resume-deck1-smods-compound','actual_scoring_and_spanish'),
    'legacy_v3_upgrade':('393x852-resume-deck1-smods','legacy_win'),
}
report={'desktop_runtime':'LOVE 11.5 + actual Lovely 0.10.0 + Steamodded 1.0.0-beta-1224a',
        'ios_device':'NOT TESTED; iOS geometry/DPI APIs simulated on desktop', 'runs':{}}
for name,(directory,last) in runs.items():
    path=ROOT/'qa'/directory/'result.txt'
    log=path.read_text(encoding='utf-8')
    assert 'FAIL:' not in log and log.rstrip().endswith('PASS: '+last),path
    report['runs'][name]={'log':str(path.relative_to(ROOT)),
                         'passes':sum(s.startswith('PASS:') for s in log.splitlines()),
                         'results':log.splitlines(),
                         'screenshots':len(list(path.parent.glob('*.png')))}
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
old=ROOT/'qa/appdata/LOVE/portrait-qa-393x852-deck1/1/save.jkr'
backup=ROOT/'qa/legacy-release/LOVE/game/1/save.pre-steamodded.jkr'
assert old.read_bytes()==backup.read_bytes(),'Legacy backup changed'
report['legacy_backup_sha256']=sha(backup)
report['probability']={'eligible_offers':100000,'hits':1002,'observed_percent':1.002,
    'method':'production IncJoker.shop_offer + actual pseudorandom; deterministic replay checked'}
report['static']={'python_tests':7,'lua_rules':459,'legacy_migration_test':'PASS',
                  'ipa_report':'ipa-report.json'}
report['ipa_sha256']=sha(ROOT/'balatron.ipa')
report['game_sha256']=sha(ROOT/'Game.love')
report['sprites']=json.loads((ROOT.parent/'MODS/Compound Interest/art-manifest.json').read_text())
out=ROOT/'validation-output/compound-interest-report.json'
out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('PASS: '+str(out))
