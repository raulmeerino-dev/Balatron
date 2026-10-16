-- Cached UIKit probes and reusable impact generators; no per-frame native calls.
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

local impact
function M.haptic(style, intensity)
    if love.system.getOS() ~= 'iOS' then return end
    if impact == false then return end
    local ok = pcall(function()
        if not impact then
            -- Reuse this wrapper's Objective-C declarations and cached probes.
            M.info()
            local ffi=require('ffi')
            local send=ffi.cast('void *(*)(void *, void *)',ffi.C.objc_msgSend)
            local init=ffi.cast('void *(*)(void *, void *, long)',ffi.C.objc_msgSend)
            local scalar=ffi.cast('void (*)(void *, void *, double)',ffi.C.objc_msgSend)
            local boolean=ffi.cast('bool (*)(void *, void *)',ffi.C.objc_msgSend)
            local responds=ffi.cast('bool (*)(void *, void *, void *)',ffi.C.objc_msgSend)
            local function sel(s) return ffi.C.sel_registerName(s) end
            local thread=ffi.C.objc_getClass('NSThread')
            if not boolean(thread,sel('isMainThread')) then return end
            local class=ffi.C.objc_getClass('UIImpactFeedbackGenerator')
            if class==nil then impact=false;return end
            local generators={}
            for i=0,2 do
                generators[i]=init(send(class,sel('alloc')),sel('initWithStyle:'),i)
            end
            impact=function(index,amount)
                if not boolean(thread,sel('isMainThread')) then return end
                local generator=generators[index] or generators[0]
                if generator==nil then return end
                send(generator,sel('prepare'))
                if responds(generator,sel('respondsToSelector:'),sel('impactOccurredWithIntensity:')) then
                    scalar(generator,sel('impactOccurredWithIntensity:'),amount or 0.6)
                else send(generator,sel('impactOccurred')) end
            end
        end
        if impact then impact(style,intensity) end
    end)
    if not ok then impact=false end
end
return M
