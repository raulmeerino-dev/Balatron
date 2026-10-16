local M=dofile('src/portrait_mods.lua')
local checks=0
local function check(value,message)
    checks=checks+1; assert(value,message)
end
local function same(a,b,os) return M.normalize_path(a,os)==M.normalize_path(b,os) end
local save='/var/mobile/Containers/Data/Application/test-container/Documents/game'
local alias='/private'..save..'/Mods/'
check(same(alias,save..'/Mods','iOS'),'Reported iPhone regression')
check(same(alias..'///',save..'/Mods','iOS'),'Multiple trailing slashes')
check(same('/private/var/','/var','iOS'),'Alias root')
check(M.normalize_path('/','iOS')=='/','Preserve root')
check(not same(alias,save..'/OtherMods','iOS'),'Different directory')
check(not same(alias,save:gsub('test%-container','other-container')..'/Mods','iOS'),'Different container')
check(not same('/private/variable/a','/variable/a','iOS'),'Prefix boundary')
check(not same(alias,save..'/mods','iOS'),'Preserve POSIX case')
check(not same(alias,save..'/Mods','Linux'),'Alias is iOS only')
check(same('C:\\Users\\Test\\Mods\\','c:/users/test/mods','Windows'),'Windows compatibility')
check(not same('/tmp/link/../Mods','/tmp/Mods','iOS'),'Do not collapse unknown symlinks')

local original_open=io.open
local module_names={'SMODS.version','SMODS.release','nativefs','json','luajit-curl','SMODS.https'}
local function fixture(options)
    options=options or {}
    for _,name in ipairs(module_names) do package.preload[name]=nil end
    PORTRAIT_MODS_READY=nil
    local files,dirs={},{}
    local state={writes=0,reads=0,closes=0,reloads=0,files=files}
    local function directory(path)
        dirs[path]=true
        local parent=path:match('^(.*)/[^/]+$')
        if parent then directory(parent) end
        return true
    end
    local function put(path,data)
        files[path]=data; directory(path:match('^(.*)/[^/]+$'))
    end
    for _,name in ipairs({'Steamodded','incremental_joker'}) do
        put('install_mods/'..name..'/.portrait_bundle',name..'-stamp')
        put('install_mods/'..name..'/main.lua','return "'..name..'"')
        put('install_mods/'..name..'/lovely.toml','[manifest]')
        put('install_mods/'..name..'/assets/sprite.png','PNG\0bytes')
    end
    for _,path in ipairs({'version.lua','release.lua','libs/nativefs/nativefs.lua',
        'libs/json/json.lua','libs/https/luajit-curl.lua','libs/https/smods-https.lua'}) do
        put('install_mods/Steamodded/'..path,'return {}')
    end
    if options.missing_mod then dirs['install_mods/incremental_joker']=nil end
    love={_os='iOS',filesystem={}}
    local fs=love.filesystem
    fs.getInfo=function(path,kind)
        if dirs[path] and (not kind or kind=='directory') then return {type='directory'} end
        if files[path] and (not kind or kind=='file') then return {type='file'} end
    end
    fs.setIdentity=function(identity) check(identity=='game','Save identity unchanged') end
    fs.getSaveDirectory=function() return options.save or save end
    fs.createDirectory=directory
    fs.getDirectoryItems=function(path)
        local names,seen={},{}
        for _,set in ipairs({files,dirs}) do for p in pairs(set) do
            if p:sub(1,#path+1)==path..'/' then
                local child=p:sub(#path+2):match('^[^/]+')
                if child and not seen[child] then names[#names+1]=child; seen[child]=true end
            end
        end end
        table.sort(names); return names
    end
    fs.read=function(path) return files[path] end
    fs.write=function(path,data)
        state.writes=state.writes+1; put(path,data); return true
    end
    fs.load=function(path) assert(files[path],'Missing preload: '..path); return function() return {} end end
    io.open=function(path,mode)
        check(mode=='rb','Native binary read only')
        check(path:sub(1,12)=='/private/var','Read using actual Lovely path')
        if options.deny then return nil,'Permission denied' end
        local p=M.normalize_path(path,'iOS')
        local prefix=M.normalize_path(fs.getSaveDirectory(),'iOS')..'/'
        local relative=p:sub(1,#prefix)==prefix and p:sub(#prefix+1)
        if not relative or not files[relative] then return nil,'Missing' end
        return {read=function(_,format)
            assert(format=='*a'); state.reads=state.reads+1; return files[relative]
        end,close=function() state.closes=state.closes+1 end}
    end
    package.loaded.lovely={mod_dir=options.actual or alias,reload_patches=function()
        state.reloads=state.reloads+1; return not options.reload_failure,'Test reload failure'
    end}
    return state
end

local s=fixture()
M.install('game')
check(PORTRAIT_MODS_READY and s.reloads==1,'Fresh alias install and patch reload')
check(s.reads==s.closes and s.reads>0,'All native file handles closed')
for _,name in ipairs({'Steamodded','incremental_joker'}) do
    check(s.files['Mods/'..name..'/main.lua']~=nil,'Mod installed')
    check(s.files['Mods/'..name..'/.portrait_bundle']==name..'-stamp','Completion marker written')
end
local writes=s.writes
M.install('game')
check(s.writes==writes and s.reloads==1,'Healthy restart does not reinstall or reload')
s.files['Mods/incremental_joker/assets/sprite.png']=nil
M.install('game')
check(s.files['Mods/incremental_joker/assets/sprite.png']=='PNG\0bytes' and s.reloads==2,'Missing file repaired despite existing stamp')
s.files['Mods/Steamodded/main.lua']='corrupt'
M.install('game')
check(s.files['Mods/Steamodded/main.lua']==s.files['install_mods/Steamodded/main.lua'],'Corrupt content repaired')
for _,options in ipairs({{actual=alias:gsub('test%-container','other-container')},
    {actual=alias:gsub('/Mods/','/OtherMods/')},{actual=alias:gsub('/Mods/','/mods/')}}) do
    s=fixture(options)
    local ok,err=pcall(M.install,'game')
    check(not ok and tostring(err):find('Lovely Mods path differs',1,true) and s.writes==0,'Reject real mismatch before copying')
end
s=fixture({save=save:gsub('test%-container','new-container'),actual=alias:gsub('test%-container','new-container')})
M.install('game'); check(PORTRAIT_MODS_READY,'Dynamic container after reinstall')
s=fixture({deny=true})
local ok,err=pcall(M.install,'game')
check(not ok and tostring(err):find('unreadable from Lovely',1,true),'Unreadable native directory is explicit')
check(not PORTRAIT_MODS_READY and s.reloads==0,'Unreadable install never claims ready')
check(not s.files['Mods/Steamodded/.portrait_bundle'],'No completion stamp on unreadable install')
s=fixture({missing_mod=true})
ok,err=pcall(M.install,'game')
check(not ok and tostring(err):find('Missing bundled mod',1,true),'Both required mods present')
s=fixture({reload_failure=true})
ok,err=pcall(M.install,'game')
check(not ok and tostring(err):find('Unable to reload',1,true) and not PORTRAIT_MODS_READY,'Actual Lovely reload failures remain visible')
io.open=original_open
print('PASS: '..checks..' installer checks: iOS alias, path boundaries, dynamic containers, native reads, fresh/restart/repair and failures')
