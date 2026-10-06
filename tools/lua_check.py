"""Check with the LuaJIT shipped in the user's local Windows Balatro copy."""
import argparse
import ctypes
from pathlib import Path


def runtime(dll):
    lua = ctypes.CDLL(str(Path(dll).resolve()))
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lua.luaL_loadfile.restype = ctypes.c_int
    lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lua.lua_close.argtypes = [ctypes.c_void_p]
    return lua


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dll', default='../Balatro/lua51.dll')
    parser.add_argument('--run', type=Path)
    parser.add_argument('root', nargs='?', default='src', type=Path)
    args = parser.parse_args()
    lua = runtime(args.dll)
    state = lua.luaL_newstate()
    lua.luaL_openlibs(state)
    files = [args.run] if args.run else sorted(args.root.rglob('*.lua'))
    for path in files:
        status = lua.luaL_loadfile(state, str(path).encode())
        if not status and args.run:
            status = lua.lua_pcall(state, 0, 0, 0)
        if status:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
        lua.lua_settop(state, 0)
    lua.lua_close(state)
    print(f'PASS: {len(files)} Lua files' + (' executed' if args.run else ' compiled'))


if __name__ == '__main__':
    main()
