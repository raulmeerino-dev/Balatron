import hashlib
import json
from pathlib import Path
import unittest

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'assets/skins/deck1'
RUNTIME = ROOT/'src/assets/skins/deck1'


class CardSkinAssetsTests(unittest.TestCase):
    def test_all_cards_and_atlas_mapping(self):
        ranks = [str(n) for n in range(2, 11)] + ['J', 'Q', 'K', 'A']
        suits = ['hearts', 'clubs', 'diamonds', 'spades']
        expected = {f'{s}_{r}.png' for s in suits for r in ranks} | {'back.png'}
        self.assertEqual({p.name for p in (SOURCE/'cards').glob('*.png')}, expected)
        manifest = json.loads((SOURCE/'manifest.json').read_text(encoding='utf-8'))
        hashes = set()
        with Image.open(RUNTIME/'fronts.png') as atlas, Image.open(RUNTIME/'enhanced.png') as enhanced:
            self.assertEqual(atlas.size, (3692, 1520))
            self.assertEqual(enhanced.size, atlas.size)
            self.assertEqual(enhanced.mode, 'RGBA')
            self.assertEqual(atlas.mode, 'RGBA')
            for name in sorted(expected):
                path = SOURCE/'cards'/name
                digest = hashlib.sha256(path.read_bytes()).hexdigest()
                self.assertEqual(digest, manifest['cards'][name]['sha256'])
                self.assertNotIn(digest, hashes, f'Duplicate card: {name}')
                hashes.add(digest)
                with Image.open(path) as card:
                    card.load()
                    self.assertEqual(card.format, 'PNG')
                    self.assertEqual(card.mode, 'RGBA')
                    self.assertEqual(card.size, (284, 380))
                    self.assertEqual(card.getpixel((0, 0))[3], 0)
                    self.assertEqual(card.getpixel((142, 190))[3], 255)
                    if name == 'back.png':
                        self.assertEqual(path.read_bytes(), (RUNTIME/name).read_bytes())
                        continue
                    suit, rank = path.stem.split('_')
                    x, y = ranks.index(rank), suits.index(suit)
                    self.assertEqual(manifest['cards'][name]['atlas_cell'], [x, y])
                    self.assertEqual(atlas.crop((x*284, y*380, (x+1)*284, (y+1)*380)).tobytes(), card.tobytes())
                    alpha = enhanced.crop((x*284, y*380, (x+1)*284, (y+1)*380)).getchannel('A')
                    self.assertLess(sum(alpha.histogram()[200:]), 284*380*.8)
        self.assertIn('approved_correction', manifest['cards']['clubs_8.png'])

    def test_sources_are_latest_deck1_sheets(self):
        manifest = json.loads((SOURCE/'manifest.json').read_text(encoding='utf-8'))
        for source in manifest['sources'].values():
            path = ROOT.parent/'DECK1'/Path(source['file'])
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), source['sha256'])

    def test_corrected_eight_has_eight_central_clubs(self):
        with Image.open(SOURCE/'cards/clubs_8.png') as image:
            # Interior only: excludes both corner indices and the frame.
            black = np.asarray(image.convert('RGB'))[65:330, 65:216].max(axis=2) < 90
        components = []
        for y in range(black.shape[0]):
            for x in range(black.shape[1]):
                if not black[y, x]:
                    continue
                pending, count = [(y, x)], 0
                black[y, x] = False
                while pending:
                    cy, cx = pending.pop()
                    count += 1
                    for ny, nx in ((cy-1,cx), (cy+1,cx), (cy,cx-1), (cy,cx+1)):
                        if 0 <= ny < black.shape[0] and 0 <= nx < black.shape[1] and black[ny,nx]:
                            black[ny,nx] = False
                            pending.append((ny,nx))
                if count > 200:
                    components.append(count)
        self.assertEqual(len(components), 8)


if __name__ == '__main__':
    unittest.main()
