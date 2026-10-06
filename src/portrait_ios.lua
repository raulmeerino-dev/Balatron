-- Read-only UIKit probes. Cached until resume; no per-frame native calls.
local M = {}
local cached

function M.info(refresh)
    if cached and not refresh then return cached end
    cached = {}
    if love.system.getOS() ~= 'iOS' then return cached end
    local ok, result = pcall(function()
        local ffi = require('ffi')
        ffi.cdef[[
            void *objc_getClass(const char *name);
            void *sel_registerName(const char *name);
            void objc_msgSend(void);
        ]]
        local send = ffi.cast('void *(*)(void *, void *)', ffi.C.objc_msgSend)
        local responds = ffi.cast('bool (*)(void *, void *, void *)', ffi.C.objc_msgSend)
        local scalar = ffi.cast('double (*)(void *, void *)', ffi.C.objc_msgSend)
        local integer = ffi.cast('long (*)(void *, void *)', ffi.C.objc_msgSend)
        local function selector(name) return ffi.C.sel_registerName(name) end
        local function available(obj, name)
            return obj ~= nil and responds(obj, selector('respondsToSelector:'), selector(name))
        end
        local screen = send(ffi.C.objc_getClass('UIScreen'), selector('mainScreen'))
        local device = send(ffi.C.objc_getClass('UIDevice'), selector('currentDevice'))
        local out = {}
        if available(screen, 'nativeScale') then out.native_scale = scalar(screen, selector('nativeScale')) end
        if available(screen, 'scale') then out.scale = scalar(screen, selector('scale')) end
        if available(screen, 'maximumFramesPerSecond') then
            out.max_fps = tonumber(integer(screen, selector('maximumFramesPerSecond')))
        end
        if available(device, 'systemVersion') then
            local version = send(device, selector('systemVersion'))
            local str = send(version, selector('UTF8String'))
            if str ~= nil then out.version = ffi.string(ffi.cast('const char *', str)) end
        end
        return out
    end)
    if ok then cached = result else cached.error = 'UIKit probe unavailable' end
    return cached
end

return M
