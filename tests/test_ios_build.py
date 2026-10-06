import importlib.util
import os
from pathlib import Path
import plistlib
import tempfile
import time
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('build', ROOT/'build.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


class IOSBuildTests(unittest.TestCase):
    def test_separate_portrait_app_and_reproducible_archive(self):
        with tempfile.TemporaryDirectory() as tmp:
            original_cwd = Path.cwd()
            try:
                os.chdir(tmp)
                Path('Game.love').write_bytes(b'local game fixture')
                app = 'Payload/Lovely.app'
                with zipfile.ZipFile('lovely-base.ipa', 'w') as z:
                    build._zip_write(z, app+'/Info.plist', plistlib.dumps({
                        'CFBundleIdentifier': 'systems.shorty.lmm',
                        'CFBundleExecutable': 'Lovely'}))
                    build._zip_write(z, app+'/Lovely', b'executable fixture', 0o100755)
                    build._zip_write(z, app+'/Game.love', b'stale bundled data')
                    build._zip_write(z, app+'/_CodeSignature/CodeResources', b'obsolete')
                    build._zip_write(z, app+'/embedded.mobileprovision', b'obsolete')
                with patch.object(build, 'WORKDIR', tmp), patch.object(build, '_download'):
                    build.build_ipa()
                    first = Path('balatro-portrait.ipa').read_bytes()
                    os.utime('Game.love', (1000000000, 1000000000))
                    build.build_ipa()
                self.assertEqual(first, Path('balatro-portrait.ipa').read_bytes())
                with zipfile.ZipFile('balatro-portrait.ipa') as z:
                    p = plistlib.loads(z.read(app+'/Info.plist'))
                    self.assertEqual(p['CFBundleIdentifier'], 'com.rulo3.balatro.portrait')
                    self.assertEqual(p['CFBundleDisplayName'], 'Balatro Portrait')
                    self.assertEqual(p['UISupportedInterfaceOrientations'], ['UIInterfaceOrientationPortrait'])
                    self.assertEqual(p['UISupportedInterfaceOrientations~ipad'], ['UIInterfaceOrientationPortrait'])
                    self.assertTrue(p['CADisableMinimumFrameDurationOnPhone'])
                    self.assertTrue(p['UIFileSharingEnabled'])
                    self.assertEqual(z.read(app+'/game.love'), b'local game fixture')
                    self.assertNotIn(app+'/Game.love', z.namelist())
                    self.assertFalse(any('_CodeSignature' in n or 'mobileprovision' in n for n in z.namelist()))
                    self.assertEqual(z.getinfo(app+'/Lovely').external_attr >> 16, 0o100755)
            finally:
                os.chdir(original_cwd)

    def test_checksum_rejects_changed_shell(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'changed.ipa'
            path.write_bytes(b'corrupt')
            with self.assertRaises(SystemExit):
                build._verify_download(build.IOS_LOVELY_BASE_URL, str(path))


if __name__ == '__main__':
    unittest.main()
