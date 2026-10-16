"""Offline structural/provenance validation. Does not claim device certification."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import plistlib
import re
import struct
import sys
import zipfile


def sha(data):
    return hashlib.sha256(data).hexdigest()


def validate(ipa, original, shell):
    from importlib.util import spec_from_file_location, module_from_spec
    root = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(root))
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
        check(plist['CFBundleDisplayName'] == build.IOS_DISPLAY_NAME and plist['CFBundleName'] == build.IOS_DISPLAY_NAME, 'Separate display name')
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
        icons, idioms = build.load_icons()
        check(len(icons) == 18, 'All 18 iPhone/iPad/marketing icon slots present')
        check(all(z.read(app+'/'+name) == data for name, data in icons.items()),
              'All app icons match the new opaque RGB jester assets')
        for key, idiom in [('CFBundleIcons', 'iphone'), ('CFBundleIcons~ipad', 'ipad')]:
            primary = plist[key]['CFBundlePrimaryIcon']
            check(primary['CFBundleIconFiles'] == idioms[idiom] and 'CFBundleIconName' not in primary,
                  key + ': new loose PNG references, no stale asset catalog')
        old_stems = build.old_icon_stems(base_plist)
        check(not any(n.endswith('.png') and re.split(r'@|~', n.rsplit('/', 1)[-1][:-4])[0]
                      in old_stems for n in names), 'Old shell app icon PNGs removed')
        report['app_icons'] = {name: sha(data) for name, data in icons.items()}
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
            required = ['main.lua', 'conf.lua', 'game.lua', 'portrait_config.lua', 'portrait_ios.lua', 'card_skins.lua', 'version.jkr']
            check(all(n in game.namelist() for n in required), 'Required Lua entry points')
            for filename, dimensions in [('fronts.png', (3692, 1520)), ('enhanced.png', (3692, 1520)), ('back.png', (284, 380))]:
                skin_path = 'assets/skins/deck1/' + filename
                png = game.read(skin_path)
                check(png == (root/'src'/skin_path).read_bytes(), 'Packaged Deck 1 matches generated asset: ' + filename)
                check(struct.unpack('>II', png[16:24]) == dimensions and png[24:26] == b'\x08\x06',
                      'Deck 1 RGBA dimensions: ' + filename)
            check(game.read('version.jkr') == local.read('version.jkr'), 'Balatro version matches local copy')
            asset_names = [n for n in local.namelist() if n.startswith(('resources/', 'localization/')) and not n.endswith('/')]
            check(all(n in game.namelist() for n in asset_names), 'All local assets present')
            changed = []
            for n in asset_names:
                if game.read(n) != local.read(n): changed.append(n)
            check(set(changed) <= {'resources/shaders/CRT.fs', 'resources/shaders/flame.fs'}, 'All assets/localizations from local copy; only known rendering shader patches')
            for shader in ('background','splash'):
                check(game.read(f'resources/shaders/{shader}.fs')==local.read(f'resources/shaders/{shader}.fs'),
                      f'Original {shader} shader byte-identical: pattern and animation preserved')
            check(re.search(rb'background_cycle_seconds\s*=\s*480\s*,',game.read('portrait_config.lua')),
                  'Extended 14-stop background cycle remains 480 seconds')
            check(b'sprite~=G.SPLASH_BACK' in game.read('portrait_background.lua')
                  and b'change_animated_background' in game.read('functions/UI_definitions.lua'),
                  'Tint confined to background sprite; persistent On/Off UI included')
            sounds = [n for n in asset_names if n.startswith('resources/sounds/')]
            check(all(game.read(n) == local.read(n) for n in sounds), f'All {len(sounds)} audio files byte-identical')
            check(not any(n.startswith(('import_save/', 'qa/')) for n in game.namelist()), 'No imported saves or QA hooks')
            expected_mods = build._bundled_mods()
            expected_paths = {'install_mods/'+mod+'/'+path: content
                              for mod, files in expected_mods.items() for path, content in files.items()}
            actual_paths = {n for n in game.namelist() if n.startswith('install_mods/')}
            check(actual_paths == set(expected_paths), 'Only configured pinned loader and local mods bundled')
            check(all(game.read(path) == content for path, content in expected_paths.items()),
                  'All bundled mod files byte-identical to normalized, stamped build inputs')
            settings = game.read('install_mods/incremental_joker/settings.lua').decode()
            joker = game.read('install_mods/incremental_joker/main.lua').decode()
            check('unlocked=true, discovered=false' in joker and not re.search(r'no_collection\s*=\s*true', joker),
                  'Compound Interest unlocked, initially undiscovered and visible in normal collection')
            check(re.search(r'debug\s*=\s*false', settings) and re.search(r'shop_probability\s*=\s*0\.01', settings),
                  'Release Joker has debug=false and 1% shop probability')
            from PIL import Image
            for key in ('compound_interest', 'tax_collector', 'hipster', 'world_record', 'excessive_force', 'collector', 'olympico'):
                for scale in (1, 2):
                    sprite = Image.open(io.BytesIO(game.read(f'install_mods/incremental_joker/assets/{scale}x/{key}.png')))
                    # Both full-bleed generated cards and transparent corners
                    # are supported; dimensions and solid illustration matter.
                    check(sprite.mode == 'RGBA' and sprite.size == (71*scale,95*scale)
                          and sprite.getextrema()[3][1] >= 250
                          and sprite.getpixel((35*scale,47*scale))[3] >= 240,
                          f'{key} {scale}x RGBA sprite with solid artwork')
            check(b"require('portrait_mods').install(t.identity)" in game.read('conf.lua')
                  and b'lovely.reload_patches()' in game.read('portrait_mods.lua'), 'Early installer reloads Lovely before main.lua')
            installer = game.read('portrait_mods.lua')
            check(installer == (root/'src/portrait_mods.lua').read_bytes().replace(b'\r\n', b'\n'),
                  'Packaged installer matches corrected source byte-for-byte')
            check(b"'^/private/var/'" in installer and b'M.normalize_path(expected,os)==M.normalize_path(actual,os)' in installer
                  and b'expected:lower()==actual:lower()' not in installer,
                  'iOS path alias and trailing slash regression fix included')
            check(b"createDirectory('Mods')" in installer and b"io.open(path,'rb')" in installer
                  and b'not readable(src,name)' in installer,
                  'Mods directory creation, native readability and incomplete install recovery included')
            check(b"t.identity = 'game'" in game.read('conf.lua'), 'Existing game save identity preserved')
            report['bundled_mods'] = {name: files['.portrait_bundle'].decode() for name,files in expected_mods.items()}
            report['runtime_note'] = 'Gameplay source comparisons precede the bundled Steamodded runtime patches; see actual Lovely desktop QA.'
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
                    expected = a.group().strip() if a else None
                    actual = b.group().strip() if b else None
                    if name == 'Card:use_consumeable' and actual:
                        # Approved Double Planets presentation: Black Hole's label
                        # reports its actual level increment. All consumption,
                        # timing, iteration and level-up calls must remain vanilla.
                        old_label = "update_hand_text({sound = 'button', volume = 0.7, pitch = 0.9, delay = 0}, {level='+1'})"
                        new_label = "update_hand_text({sound = 'button', volume = 0.7, pitch = 0.9, delay = 0},\n            {level='+'..tostring(PortraitRunRules and PortraitRunRules.planet_level_amount(self,1) or 1)})"
                        check(actual.count(new_label) == 1 and expected and expected.count(old_label) == 1,
                              'Black Hole level label uses the approved Double Planets increment')
                        actual = actual.replace(new_label, old_label, 1)
                    check(expected is not None and actual == expected,
                          'Original gameplay function: '+name)
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
    parser.add_argument('--ipa', default='balatron.ipa')
    parser.add_argument('--original', default='../Balatro/Balatro.exe')
    parser.add_argument('--shell', default='balatro-mobile-maker/lovely-base.ipa')
    parser.add_argument('--output', default='validation-output/ipa-report.json')
    args = parser.parse_args()
    result = validate(args.ipa, args.original, args.shell)
    output = Path(args.output); output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(f"PASS: {len(result['checks'])} checks; {result['game_files']} game files; report: {output}")
