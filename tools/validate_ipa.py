"""Offline structural/provenance validation. Does not claim device certification."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import plistlib
import re
import struct
import zipfile


def sha(data):
    return hashlib.sha256(data).hexdigest()


def validate(ipa, original, shell):
    from importlib.util import spec_from_file_location, module_from_spec
    root = Path(__file__).resolve().parents[1]
    spec = spec_from_file_location('portrait_build', root/'build.py')
    build = module_from_spec(spec); spec.loader.exec_module(build)
    report = {'status': 'PASS', 'checks': [], 'device_validation': 'pending'}

    def check(condition, message):
        if not condition:
            raise AssertionError(message)
        report['checks'].append(message)

    with zipfile.ZipFile(ipa) as z, zipfile.ZipFile(original) as local, zipfile.ZipFile(shell) as base:
        names = z.namelist()
        check(z.testzip() is None, 'IPA CRC integrity')
        check(len(names) == len(set(names)), 'No duplicate ZIP entries')
        check(all(not PurePosixPath(n).is_absolute() and '..' not in PurePosixPath(n).parts and '\\' not in n for n in names), 'Relative portable paths')
        app = build._ios_app_dir(z)
        plist = plistlib.loads(z.read(app+'/Info.plist'))
        report['plist'] = plist
        check(plist['CFBundleIdentifier'] == build.IOS_BUNDLE_ID, 'Separate bundle identifier')
        check(plist['CFBundleDisplayName'] == 'Balatro Portrait', 'Separate display name')
        for key in ('UISupportedInterfaceOrientations', 'UISupportedInterfaceOrientations~ipad'):
            check(plist[key] == ['UIInterfaceOrientationPortrait'], key + ': portrait only')
        check(plist.get('CADisableMinimumFrameDurationOnPhone') is True, 'ProMotion opt-in')
        check(plist.get('UIFileSharingEnabled') and plist.get('LSSupportsOpeningDocumentsInPlace'), 'Files document access')
        executable = app+'/'+plist['CFBundleExecutable']
        code = z.read(executable)
        check(z.getinfo(executable).external_attr >> 16 & 0o111, 'Executable permissions')
        check(code[:4] == b'\xcf\xfa\xed\xfe', '64-bit Mach-O shell')
        check(struct.unpack_from('<I', code, 4)[0] == 0x0100000c, 'ARM64 architecture')
        base_app = build._ios_app_dir(base)
        base_plist = plistlib.loads(base.read(base_app+'/Info.plist'))
        check(code == base.read(base_app+'/'+base_plist['CFBundleExecutable']), 'Native executable unchanged from pinned open-source shell')
        check(b'lovely' in code and b'Mods' in code, 'Lovely and Mods markers in native executable')
        offset, dylibs, encrypted = 32, [], False
        for _ in range(struct.unpack_from('<I', code, 16)[0]):
            command, size = struct.unpack_from('<II', code, offset)
            if size < 8 or offset+size > len(code):
                raise AssertionError('Invalid Mach-O load command')
            if command in (0x21, 0x2c):
                encrypted |= struct.unpack_from('<I', code, offset+16)[0] != 0
            if command in (0xc, 0x80000018, 0x8000001f):
                start = offset+struct.unpack_from('<I', code, offset+8)[0]
                dylibs.append(code[start:code.index(b'\0', start)].decode())
            offset += size
        check(not encrypted, 'Native shell is not FairPlay encrypted')
        check(all(n.startswith(('/System/Library/', '/usr/lib/')) for n in dylibs), 'All native dynamic dependencies are system libraries')
        report['native_dependencies'] = dylibs
        check(not any('/_CodeSignature/' in n or n.endswith('embedded.mobileprovision') for n in names), 'No obsolete bundle signatures/provisioning')
        # A Mach-O ad-hoc signature may remain; the installation tool must re-sign.
        data = z.read(app+'/game.love')
        check(sha(data) == sha((root/'Game.love').read_bytes()), 'Embedded Game.love matches build')
        with zipfile.ZipFile(io.BytesIO(data)) as game:
            check(game.testzip() is None, 'Game.love CRC integrity')
            check(len(game.namelist()) == len(set(game.namelist())), 'No duplicate game entries')
            required = ['main.lua', 'conf.lua', 'game.lua', 'portrait_config.lua', 'portrait_ios.lua', 'version.jkr']
            check(all(n in game.namelist() for n in required), 'Required Lua entry points')
            check(game.read('version.jkr') == local.read('version.jkr'), 'Balatro version matches local copy')
            asset_names = [n for n in local.namelist() if n.startswith(('resources/', 'localization/')) and not n.endswith('/')]
            check(all(n in game.namelist() for n in asset_names), 'All local assets present')
            changed = []
            for n in asset_names:
                if game.read(n) != local.read(n): changed.append(n)
            check(set(changed) <= {'resources/shaders/CRT.fs', 'resources/shaders/flame.fs'}, 'All assets/localizations from local copy; only known rendering shader patches')
            sounds = [n for n in asset_names if n.startswith('resources/sounds/')]
            check(all(game.read(n) == local.read(n) for n in sounds), f'All {len(sounds)} audio files byte-identical')
            check(not any(n.startswith(('import_save/', 'install_mods/', 'qa/')) for n in game.namelist()), 'No imported saves, optional mods or QA hooks')
            check(b'qa_harness' not in game.read('main.lua'), 'No desktop test harness in production')
            check(b"t.window.highdpi = (love._os == 'iOS')" in game.read('conf.lua'), 'iOS high-DPI window requested')
            check(b't.window.usedpiscale = true' in game.read('conf.lua'), 'Logical DPI coordinates enabled')
            missing = []
            crlf_sources = []
            for n in game.namelist():
                if not n.endswith('.lua') or n.startswith('localization/'): continue
                source = game.read(n).decode('utf-8-sig')
                if '\r\n' in source: crlf_sources.append(n)
                for module in re.findall(r'\brequire\s*(?:\(\s*)?[\'\"]([^\'\"]+)', source):
                    if module.startswith(('engine/', 'functions/', 'portrait_')) and module != 'portrait_shaders':
                        if module+'.lua' not in game.namelist(): missing.append((n, module))
            check(not missing, 'Internal Lua module references resolve')
            check(not crlf_sources, 'All packaged Lua uses LF for Lovely patch compatibility')
            literal_assets = set()
            for n in game.namelist():
                if n.endswith('.lua') and not n.startswith('localization/'):
                    literal_assets.update(re.findall(r'[\'\"](resources/[^\'\"]+\.(?:ttf|ogg|png|fs))[\'\"]', game.read(n).decode('utf-8-sig')))
            # The error handler tries Readabletro under pcall, then falls back
            # to the bundled original font. This optional font is not shipped.
            optional_assets = {'resources/fonts/TypoQuik-Bold.ttf'}
            report['optional_assets_absent'] = sorted(optional_assets - set(game.namelist()))
            check(all(n in game.namelist() for n in literal_assets - optional_assets), 'Required literal font, shader, sound and image paths exist')
            core_functions = {
                'functions/misc_functions.lua': ['pseudorandom_element', 'pseudoseed', 'pseudorandom',
                    'evaluate_poker_hand', 'get_flush', 'get_straight', 'get_X_same'],
                'card.lua': ['Card:calculate_joker', 'Card:calculate_seal', 'Card:get_chip_bonus', 'Card:use_consumeable'],
            }
            for filename, functions in core_functions.items():
                vanilla = local.read(filename).decode('utf-8-sig').replace('\r\n', '\n')
                portrait = game.read(filename).decode('utf-8-sig')
                for name in functions:
                    pattern = r'^function '+re.escape(name)+r'\(.*?(?=^function |\Z)'
                    a, b = re.search(pattern, vanilla, re.M|re.S), re.search(pattern, portrait, re.M|re.S)
                    check(a and b and a.group().strip() == b.group().strip(), 'Original gameplay function: '+name)
            report['game_files'] = len(game.namelist())
            report['local_assets'] = len(asset_names)
            report['changed_assets'] = changed
            report['game_sha256'] = sha(data)
            report['balatro_version'] = game.read('version.jkr').decode().splitlines()[0]
        report['ipa_sha256'] = sha(Path(ipa).read_bytes())
        report['local_exe_sha256'] = sha(Path(original).read_bytes())
        report['shell_sha256'] = sha(Path(shell).read_bytes())
        check(report['shell_sha256'] == build.TOOL_SHA256[build.IOS_LOVELY_BASE_URL], 'Pinned Lovely shell SHA-256')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ipa', default='balatro-portrait.ipa')
    parser.add_argument('--original', default='../Balatro/Balatro.exe')
    parser.add_argument('--shell', default='balatro-mobile-maker/lovely-base.ipa')
    parser.add_argument('--output', default='validation-output/ipa-report.json')
    args = parser.parse_args()
    result = validate(args.ipa, args.original, args.shell)
    output = Path(args.output); output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(f"PASS: {len(result['checks'])} checks; {result['game_files']} game files; report: {output}")
