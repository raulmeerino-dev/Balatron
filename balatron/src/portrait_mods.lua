-- Install the bundled, pinned mods before Lovely reads main.lua. Runs in conf.
local M = {}
-- conf runs before nativefs/Steamodded are available. Avoid a new native/FFI
-- realpath dependency here; normalize only the known iOS directory alias.
-- Keep POSIX case and component boundaries: /private/variable is NOT /var.
function M.normalize_path(path, os)
    assert(type(path)=='string' and path~='', 'Missing mods directory path')
    if os=='Windows' then path=path:gsub('\\','/') end
    path=path:gsub('/+$','')
    if path=='' then path='/' end
    if os=='iOS' then
        if path=='/private/var' then path='/var'
        else path=path:gsub('^/private/var/','/var/') end
    elseif os=='Windows' then path=path:lower() end
    return path
end
function M.install(identity)
    if not love.filesystem.getInfo('install_mods') then return end
    local ok, lovely = pcall(require, 'lovely')
    -- Plain desktop QA can still inspect the unmodded game; iOS must not silently
    -- claim that the requested Joker is available without its actual loader.
    if not ok then
        if love._os == 'iOS' then error('Bundled mods require Lovely 0.10.0') end
        return
    end
    love.filesystem.setIdentity(identity)
    local os = love._os or love.system.getOS()
    local expected = love.filesystem.getSaveDirectory()..'/Mods'
    local actual = lovely.mod_dir
    assert(M.normalize_path(expected,os)==M.normalize_path(actual,os),
        'Lovely Mods path differs from save path: '..tostring(actual)..' / '..expected)
    assert(love.filesystem.createDirectory('Mods'), 'Unable to create save Mods directory')
    assert(love.filesystem.getInfo('Mods','directory'), 'Save Mods directory is missing')
    for _,name in ipairs({'Steamodded','incremental_joker'}) do
        assert(love.filesystem.getInfo('install_mods/'..name,'directory'), 'Missing bundled mod: '..name)
    end
    -- Read through Lovely's ORIGINAL absolute path, not the normalized alias.
    -- This checks actual on-disk accessibility beyond Love's virtual filesystem.
    local native_root=actual:gsub('/+$','')
    local function readable(src,relative)
        for _,name in ipairs(love.filesystem.getDirectoryItems(src)) do
            if name~='.portrait_bundle' then
                local sp,rp=src..'/'..name,relative..'/'..name
                if love.filesystem.getInfo(sp,'directory') then
                    local valid,err=readable(sp,rp)
                    if not valid then return false,err end
                else
                    local path=native_root..'/'..rp
                    local file,err=io.open(path,'rb')
                    if not file then return false,path..': '..tostring(err) end
                    local data=file:read('*a'); file:close()
                    if data~=assert(love.filesystem.read(sp)) then
                        return false,path..': missing or different contents'
                    end
                end
            end
        end
        return true
    end
    local changed = false
    local function copy(src,dst)
        assert(love.filesystem.createDirectory(dst))
        for _,name in ipairs(love.filesystem.getDirectoryItems(src)) do
            local sp,dp=src..'/'..name,dst..'/'..name
            if love.filesystem.getInfo(sp,'directory') then copy(sp,dp)
            elseif name~='.portrait_bundle' then assert(love.filesystem.write(dp,assert(love.filesystem.read(sp)))) end
        end
    end
    for _,name in ipairs(love.filesystem.getDirectoryItems('install_mods')) do
        local src,dst='install_mods/'..name,'Mods/'..name
        if love.filesystem.getInfo(src,'directory') then
            local stamp=assert(love.filesystem.read(src..'/.portrait_bundle'))
            if love.filesystem.read(dst..'/.portrait_bundle')~=stamp or not readable(src,name) then
                copy(src,dst)
                local valid,err=readable(src,name)
                assert(valid, 'Bundled mod unreadable from Lovely Mods directory: '..tostring(err))
                -- Write the completion marker last: an interrupted copy retries.
                assert(love.filesystem.write(dst..'/.portrait_bundle',stamp))
                changed=true
            end
        end
    end
    if changed then
        local loaded,err=lovely.reload_patches()
        assert(loaded, 'Unable to reload bundled Lovely patches: '..tostring(err))
    end
    -- Lovely 0.10 registers module patches only when its Lua API is first
    -- injected. On a clean install that precedes copying the bundled files.
    -- Preload the SAME upstream modules so first launch also works.
    for name,path in pairs({['SMODS.version']='version.lua', ['SMODS.release']='release.lua',
        nativefs='libs/nativefs/nativefs.lua', json='libs/json/json.lua',
        ['luajit-curl']='libs/https/luajit-curl.lua', ['SMODS.https']='libs/https/smods-https.lua'}) do
        if not package.preload[name] then
            package.preload[name]=assert(love.filesystem.load('Mods/Steamodded/'..path))
        end
    end
    PORTRAIT_MODS_READY=true
end
return M
