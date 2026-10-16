-- Expansion state belongs to the run/profile, never to a UI object or closure.
local X={version=1,catalog=require('expansion48.catalog'),listeners={}}
PortraitExpansion48=X
function X.es() return (G.SETTINGS.language or ''):sub(1,2)=='es' end
function X.text(es,en) return X.es() and es or en end
function X.state()
    if not G.GAME or G.STAGE~=G.STAGES.RUN or G.GAME.portrait_stock_preview then return end
    G.GAME.expansion48=G.GAME.expansion48 or {version=1,serial=0,receipts={},pending={},graveyard={},metrics={}}
    return G.GAME.expansion48
end
function X.profile()
    local p=G.PROFILES and G.PROFILES[G.SETTINGS.profile];if not p then return end
    p.expansion48=p.expansion48 or {version=1,unlocked={},discovered={},notices={},seen={}}
    local s=p.expansion48
    if p.all_unlocked then
        for id in pairs(X.catalog) do s.unlocked[id]=true;s.discovered[id]=true;s.seen[id]=true end
        s.notices={}
    end
    return s
end
function X.persist() G:save_progress();if G.FILE_HANDLER then G.FILE_HANDLER.force=true end end
function X.checkpoint() if X.state() then save_run() end end
function X.unlocked(id) local p=X.profile();return p and p.unlocked[id]==true end
function X.discovered(id) local p=X.profile();return p and p.discovered[id]==true end
function X.discover(id)
    local p=X.profile();if p and not p.discovered[id] then p.discovered[id]=true;X.persist() end
end
function X.unlock(id)
    local p,s=X.profile(),X.state()
    if not p or not s or G.GAME.seeded or G.GAME.challenge or p.unlocked[id] then return end
    p.unlocked[id]=true;p.discovered[id]=true;p.notices[#p.notices+1]=id
    X.sync_centers()
    check_for_unlock{type='portrait_expansion48',id=id}
    X.persist()
end
function X.catalog_id(kind,key)
    local category=({mutations='Mutation',contracts='Contract',contraband='Contraband'})[kind]
    for id,d in pairs(X.catalog) do if d.category==category and d.key==key then return id end end
end
function X.sync_centers()
    local p=X.profile();if not p then return end
    local changed=false;local locked={}
    for i=#(G.P_LOCKED or {}),1,-1 do
        local center=G.P_LOCKED[i]
        if center.expansion48 and p.unlocked[center.expansion48] then table.remove(G.P_LOCKED,i);changed=true
        else locked[center.key]=true end
    end
    for _,center in pairs(G.P_CENTERS or {}) do
        if center.expansion48 then
            local unlocked=p.unlocked[center.expansion48]==true
            if center.unlocked~=unlocked then changed=true end
            center.unlocked=unlocked
            if not unlocked and G.P_LOCKED and not locked[center.key] then
                G.P_LOCKED[#G.P_LOCKED+1]=center;locked[center.key]=true;changed=true
            end
        end
    end
    if changed and set_discover_tallies then set_discover_tallies() end
end
function X.decorate(def,id)
    def.expansion48=id;def.unlocked=false;def.discovered=false
    def.unlock_condition={type='portrait_expansion48'}
    def.check_for_unlock=function(_,args) return args.type=='portrait_expansion48' and args.id==id and X.unlocked(id) end
    return def
end
function X.id(card)
    local s=X.state();if not s or not card or not card.ability then return end
    if not card.ability.exp48_id then s.serial=s.serial+1;card.ability.exp48_id='e48:'..s.serial end
    return card.ability.exp48_id
end
function X.find(id,area)
    for _,c in ipairs(area or G.playing_cards or {}) do if c.ability.exp48_id==id and not c.removed then return c end end
end
function X.count(t) local n=0;for _ in pairs(t or {}) do n=n+1 end;return n end
function X.set(cards) local t={};for _,c in ipairs(cards or {}) do t[X.id(c)]=true end;return t end
function X.blind() return PortraitGameplay.token() end
function X.once(key)
    local s=X.state();if not s or s.receipts[key] then return false end;s.receipts[key]=true;return true
end
function X.has(key)
    if not G.jokers then return false end
    for _,c in ipairs(G.jokers.cards) do
        if c.config.center.key==key and not c.debuff and not c.removed and not c.getting_sliced then return c end
    end
    return false
end
function X.mutation(id)
    return PortraitRunRules and PortraitRunRules.has(X.catalog[id].key) or false
end
function X.listen(fn) X.listeners[#X.listeners+1]=fn end
function X.track(context)
    if not X.state() then return end
    for _,fn in ipairs(X.listeners) do fn(context) end
end
function X.eligible(key)
    local c=G.P_CENTERS[key]
    return c and c.unlocked~=false and (not c.expansion48 or X.unlocked(c.expansion48))
        and not G.GAME.banned_keys[key] and SMODS.add_to_pool(c,{source='expansion48'})
end
-- Copies are new physical objects. Transforming an existing card retains its ID.
local copy=copy_card
function copy_card(other,new_card,...)
    local identity=new_card and new_card.ability and new_card.ability.exp48_id
    local result=copy(other,new_card,...)
    if result and result.ability then result.ability.exp48_id=identity;X.id(result) end
    return result
end
local queued={}
local notify=unlock_notify
function unlock_notify(...)
    local result=notify(...)
    if G.STAGE~=G.STAGES.MAIN_MENU then return result end
    local p=X.profile();local profile=G.SETTINGS.profile
    for _,id in ipairs(p and p.notices or {}) do
        local token=tostring(profile)..':'..id
        if not queued[token] and not p.seen[id] then
            queued[token]=true
            create_unlock_overlay('exp48_'..id,{
                valid=function()
                    local valid=G.SETTINGS.profile==profile and G.STAGE==G.STAGES.MAIN_MENU and not p.seen[id]
                    if not valid then queued[token]=nil end;return valid
                end,
                definition=function()
                    if X.notice_definition then local definition=X.notice_definition(id);if definition then return definition end end
                    local d=X.catalog[id];local P=PortraitGameplay
                    return create_UIBox_generic_options{contents={P.text(X.text('DESBLOQUEADO','UNLOCKED'),0.5),
                        P.text(X.text(d.name,d.name_en),0.45)},back_func='exit_overlay_menu'}
                end,
                shown=function(box) box.exp48_notice={id=id,profile=profile};if X.notice_shown then X.notice_shown(id,box) end end,
            })
        end
    end
    return result
end
local exit=G.FUNCS.exit_overlay_menu
G.FUNCS.exit_overlay_menu=function(...)
    local n=G.OVERLAY_MENU and G.OVERLAY_MENU.exp48_notice
    if n and n.profile==G.SETTINGS.profile then
        local p=X.profile();p.seen[n.id]=true
        for i=#p.notices,1,-1 do if p.notices[i]==n.id then table.remove(p.notices,i) end end
        queued[tostring(n.profile)..':'..n.id]=nil;X.persist()
    end
    return exit(...)
end
local unlock_all=G.FUNCS.unlock_all
G.FUNCS.unlock_all=function(...)
    local result=unlock_all(...);X.profile();X.sync_centers();X.persist();return result
end
return X
