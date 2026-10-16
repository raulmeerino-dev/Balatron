import hashlib
import importlib.util
import json
from pathlib import Path
import unittest
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
MOD=ROOT.parent/'MODS'/'Compound Interest'

class CompoundAssetsTests(unittest.TestCase):
    def test_source_and_explicit_resolution_variants(self):
        manifest=json.loads((MOD/'art-manifest.json').read_text())['compound_interest']
        self.assertEqual(hashlib.sha256((MOD/manifest['source']).read_bytes()).hexdigest(),manifest['sha256'])
        for scale in (1,2):
            path=MOD/'assets'/f'{scale}x'/'compound_interest.png'
            with Image.open(path) as im:
                self.assertEqual(im.mode,'RGBA')
                self.assertEqual(im.size,(71*scale,95*scale))
                # The approved family master retains slight paper translucency.
                low,high=im.getextrema()[3]
                self.assertLessEqual(low,8)
                self.assertGreaterEqual(high,248)
                self.assertGreaterEqual(im.getpixel((35*scale,50*scale))[3],248)
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),manifest['sprites'][str(scale)]['sha256'])

    def test_mod_registration_localizations_and_bundle(self):
        metadata=json.loads((MOD/'mod.json').read_text())
        self.assertEqual(metadata['id'],'incremental_joker')
        self.assertEqual(metadata['prefix'],'incj')
        source=(MOD/'main.lua').read_text(encoding='utf-8')
        self.assertIn('unlocked=true, discovered=false',source)
        self.assertNotRegex(source,r'no_collection\s*=\s*true')
        for language in ('en-us','es_ES','es_419'):
            self.assertIn('j_incj_compound_interest',(MOD/'localization'/f'{language}.lua').read_text(encoding='utf-8'))
        spec=importlib.util.spec_from_file_location('portrait_build',ROOT/'build.py')
        build=importlib.util.module_from_spec(spec); spec.loader.exec_module(build)
        bundled=build._bundled_mods()
        self.assertEqual(set(bundled),{'Steamodded','incremental_joker','upgraded_jokers','risk_jokers','portrait_events',
                                     'portrait_gameplay','deck_mutations','contracts','joker_fusion','portrait_horizons'})
        self.assertNotIn('arte_original.png',bundled['incremental_joker'])
        self.assertNotIn('art-manifest.json',bundled['incremental_joker'])
        self.assertNotIn('expansion-art-prompts.json',bundled['contracts'])
        self.assertNotIn('reward-plan.json',bundled['contracts'])
        self.assertIn('LICENSE',bundled['Steamodded'])
        for files in bundled.values():
            digest=hashlib.sha256()
            for path,data in sorted(files.items()):
                if path!='.portrait_bundle': digest.update(path.encode()+b'\0'+data)
            self.assertEqual(files['.portrait_bundle'],digest.hexdigest().encode())

if __name__=='__main__': unittest.main()
