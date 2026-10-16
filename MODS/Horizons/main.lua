local mod=SMODS.current_mod
local H={mod=mod,X=PortraitExpansion48,P=PortraitGameplay,installers={},profile_checks={},version=1}
PortraitHorizons=H
H.module=H.P.register(mod)
H.meta=assert(SMODS.load_file('catalog.lua'))()
for id,d in pairs(H.meta) do H.X.catalog[id]=d end
H.text=H.X.text
function H.lines(text,limit)
    local lines,line={},'';limit=limit or 38
    for word in (text or ''):gmatch('%S+') do
        if #line>0 and #line+#word+1>limit then lines[#lines+1]=line;line=word
        else line=line=='' and word or line..' '..word end
    end
    if line~='' then lines[#lines+1]=line end;return lines
end
function H.key(id) return H.meta[id] and H.meta[id].key end
function H.state()
    if not H.X.state() then return end
    local s=H.module.state();if not s then return end
    s.version=s.version or H.version;s.receipts=s.receipts or {};s.metrics=s.metrics or {}
    return s
end
function H.config()
    if G.STAGE==G.STAGES.RUN and G.GAME then return G.GAME[mod.id..'_config'] or {enabled=false} end
    return mod.config
end
function H.enabled(category,id)
    local c=H.config()
    return c.enabled==true and (not c.categories or c.categories[category]~=false)
        and (not id or not c.items or c.items[id]~=false)
end
H.unlocked=H.X.unlocked
function H.unlock(id,from_profile)
    if not H.meta[id] then return end
    if from_profile then
        if not H.meta[id].profile_unlock or G.STAGE~=G.STAGES.MAIN_MENU then return end
        local p=H.X.profile();if not p or p.unlocked[id] then return end
        p.unlocked[id]=true;p.discovered[id]=true;p.notices[#p.notices+1]=id
        H.sync();H.X.persist();return true
    end
    H.X.unlock(id);H.sync()
end
function H.once(key)
    local s=H.state();if not s or s.receipts[key] then return false end
    s.receipts[key]=true;return true
end
function H.on(fn) H.X.listen(function(c) if H.state() then fn(c) end end) end
function H.on_profile(fn) H.profile_checks[#H.profile_checks+1]=fn end
function H.check_profile() for _,fn in ipairs(H.profile_checks) do fn() end end
function H.atlas(key,path,px,py)
    SMODS.Atlas{key=key,path=path,px=px or 71,py=py or 95,disable_mipmap=true,
        inject=function(self) SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest') end}
    return key
end
function H.decorate(def,id)
    local pool=def.in_pool;H.X.decorate(def,id);def.horizons=id
    def.in_pool=function(self,args)
        if not H.unlocked(id) or not H.enabled(H.meta[id].category,id) then return false end
        if pool then return pool(self,args) end;return true
    end
    if type(def.loc_txt)=='table' then
        for lang,t in pairs(def.loc_txt) do
            if type(t)=='table' and (lang=='en-us' or lang:sub(1,2)=='es') and not t.unlock then
                t.unlock=H.lines(lang:sub(1,2)=='es' and H.meta[id].unlock or H.meta[id].unlock_en or H.meta[id].unlock)
            end
        end
    end
    return def
end
function H.sync()
    H.X.sync_centers()
    local p=H.X.profile();if not p then return end
    for id,d in pairs(H.meta) do
        local obj=(G.P_CENTERS and G.P_CENTERS[d.key]) or (G.P_BLINDS and G.P_BLINDS[d.key]) or (G.P_TAGS and G.P_TAGS[d.key])
        if obj then
            obj.horizons=id
            if type(obj.unlocked)~='function' then obj.unlocked=p.unlocked[id]==true end
            obj.discovered=p.discovered[id]==true
        end
    end
end
function H.install()
    if H.installed then return end;H.installed=true
    for _,fn in ipairs(H.installers) do fn() end
    local restore=SMODS.SAVE_UNLOCKS
    function SMODS.SAVE_UNLOCKS(...) local r=restore(...);H.sync();return r end
    local notify=unlock_notify
    function unlock_notify(...) H.check_profile();H.sync();return notify(...) end
    local all=G.FUNCS.unlock_all
    G.FUNCS.unlock_all=function(...) local r=all(...);H.sync();return r end
    H.sync()
end
local begin=H.P.begin_run
function H.P.begin_run(...)
    local r=begin(...);H.state();H.sync();return r
end
for _,file in ipairs({'challenges','bosses','vouchers','tags','packs','decks','feedback','ui'}) do
    assert(SMODS.load_file(file..'.lua'))()(H)
end
