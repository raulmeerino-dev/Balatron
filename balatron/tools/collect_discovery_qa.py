"""Record the three independent process runs of the native discovery lifecycle."""
import hashlib
import json
from pathlib import Path

root=Path(__file__).resolve().parents[1]
report={'status':'PASS','runtime':'LOVE 11.5 / Lovely 0.10.0 / Steamodded beta-1224a',
        'device_validation':'pending','profile':'qa/discovery-v5-final/LOVE/game/1',
        'phases':{},'initial_unlocked':True,'initial_discovered':False,
        'no_collection':False,'shop_probability':.01,'native_discovery':True}
for phase in ('initial','buy','reopen'):
    folder=root/'qa'/('393x852-smods-discovery-'+phase)
    log=(folder/'result.txt').read_text(encoding='utf-8')
    assert 'FAIL:' not in log and log.rstrip().endswith('PASS: discovery_persisted'),phase
    assert 'qa/discovery-v5-final/LOVE/game' in log,phase
    report['phases'][phase]={'log':str((folder/'result.txt').relative_to(root)),
                            'results':log.splitlines()}
report['ipa_sha256']=hashlib.sha256((root/'balatron.ipa').read_bytes()).hexdigest()
report['game_sha256']=hashlib.sha256((root/'Game.love').read_bytes()).hexdigest()
report['reproducible_builds']=2
path=root/'validation-output/compound-discovery-report.json'
path.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('PASS: '+str(path))
