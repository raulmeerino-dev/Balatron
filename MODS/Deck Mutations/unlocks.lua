-- Profile progression and run receipts share one owner. Offers are immutable snapshots.
return function(P,M,order)
    local U={};PortraitModifierUnlocks=U
    local requirements=assert(SMODS.load_file('progression.lua'))()
    local expansion_ids={}
    for _,d in ipairs(order) do if d.expansion48 then
        local meta=PortraitExpansion48.catalog[d.expansion48]
        expansion_ids[d.id]=d.expansion48
        requirements[d.id]={'exp48_'..d.expansion48,1,'run',meta.unlock,meta.unlock_en or meta.unlock}
    end end
    U.definitions={};U.requirements=requirements
    for _,d in ipairs(order) do
        d.unlock_condition=requirements[d.id];d.unlock_required=d.unlock_condition~=nil
        U.definitions[d.id]=d
    end
    local function save() G:save_progress();G.FILE_HANDLER.force=true end
    assert(SMODS.load_file('profile.lua'))()(U,order,requirements,save)
    function U.run()
        if G.STAGE~=G.STAGES.RUN or G.GAME.portrait_stock_preview then return end
        if not G.GAME.portrait_modifier_progress then
            local p=U.profile();p.serial=(p.serial or 0)+1
            G.GAME.portrait_modifier_progress={id=tostring(p.serial),stats={},receipts={},edition_cards={}}
            save()
        end
        return G.GAME.portrait_modifier_progress
    end
    function U.unlocked(id)
        if expansion_ids[id] then return PortraitExpansion48.unlocked(expansion_ids[id]) end
        local p=U.profile();return p and p.unlocked[id] or false
    end
    function U.unlock(id,quiet)
        if expansion_ids[id] then return PortraitExpansion48.unlock(expansion_ids[id]) end
        local p=U.profile();if not p or not U.definitions[id] or p.unlocked[id] then return end
        p.unlocked[id]=true;p.discovered[id]=true
        if not quiet then p.pending_notifications[#p.pending_notifications+1]=id else p.seen_notifications[id]=true end
        save()
    end
    function U.check()
        local p,r=U.profile(),U.run();if not p then return end
        for _,d in ipairs(order) do local c=d.unlock_condition
            if c and not expansion_ids[d.id] and not p.unlocked[d.id] then
                local s=c[3]=='profile' and p.stats or p.evaluate_legacy and p.best_run or r and r.stats or {}
                if (s[c[1]] or 0)>0 then U.discover(d.id) end
                if (s[c[1]] or 0)>=c[2] then U.unlock(d.id) end
            end
        end
        if p.evaluate_legacy then p.evaluate_legacy=nil;save() end
    end
    function U.record(key,amount,receipt,maximum)
        local p,r=U.profile(),U.run();if not p or not r then return end
        if receipt then receipt=key..':'..tostring(receipt);if r.receipts[receipt] then return end;r.receipts[receipt]=true end
        local previous=r.stats[key] or 0
        r.stats[key]=maximum and math.max(previous,amount) or previous+amount
        if r.stats[key]==previous then return end
        -- Profile high-water receipts prevent reloading an earlier run snapshot
        -- from counting the same purchases/discards/rewards a second time.
        p.runs=p.runs or {};p.runs[r.id]=p.runs[r.id] or {}
        local paid=p.runs[r.id][key] or 0
        if maximum then p.stats[key]=math.max(p.stats[key] or 0,r.stats[key])
        else p.stats[key]=(p.stats[key] or 0)+math.max(0,r.stats[key]-paid) end
        p.runs[r.id][key]=math.max(paid,r.stats[key])
        p.best_run[key]=math.max(p.best_run[key] or 0,r.stats[key])
        U.check();save()
    end
    function U.info(id)
        if expansion_ids[id] then
            local x=PortraitExpansion48;local d=x.catalog[expansion_ids[id]]
            return {title=x.text(d.name,d.name_en),text={x.text('Bloqueado','Locked'),x.text(d.unlock,d.unlock_en or d.unlock)}}
        end
        local c=requirements[id];local p,r=U.profile(),U.run()
        local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
        local s=c and (c[3]=='profile' and p.stats or r and r.stats or p.best_run) or {}
        return {title=localize('k_dm_'..id),text={es and 'Bloqueado' or 'Locked',c and c[es and 4 or 5] or '',
            c and (math.min(s[c[1]] or 0,c[2])..' / '..c[2]) or '',
            c and c[3]=='run' and (r and (es and 'En esta run' or 'This run') or (es and 'Mejor intento en una run' or 'Best single-run attempt')) or ''}}
    end
    function U.jokers()
        local r=U.run();if not r or not G.jokers then return end
        local count=0
        for _,card in ipairs(G.jokers.cards) do if card.added_to_deck and not card.cb_preview then
            count=count+1
            local c=card.config.center
            if c.risk_id then U.record('risk',1,nil,true) end
            if c.portrait_family=='doubles' then U.record('doubles',1,nil,true) end
            if c.rarity==3 or c.rarity=='Rare' then U.record('rare',1,nil,true) end
            if card.edition then
                local id=tostring(card.sort_id)
                if not r.edition_cards[id] then r.edition_cards[id]=true;U.record('editions',1) end
                if card.edition.negative then U.record('negative',1,nil,true) end
            end
        end end
        if count>(r.stats.jokers or 0) then U.record('jokers',count,nil,true) end
    end
    function U.context(c)
        if not P.real(c) or not U.run() then return end
        if c.open_booster then U.record('packs',1,'card:'..tostring(c.card.sort_id)) end
        if c.selling_card then U.record('sales',1,'card:'..tostring(c.card.sort_id)) end
        if c.reroll_shop then U.record('rerolls',1) end
        if c.pseudorandom_result and c.result and (not PortraitRunRules or PortraitRunRules.favorable(c.trigger_obj,c.identifier)) and (c.numerator or 0)<(c.denominator or 1) then U.record('luck',1) end
        if P.won(c) and c.beat_boss then U.record('bosses',1,P.token()) end
        if c.buying_card or c.card_added or c.setting_blind then
            G.E_MANAGER:add_event(Event{blocking=false,func=function() U.jokers();return true end})
        end
    end
    local check=check_for_unlock
    function check_for_unlock(args,...)
        local result=check(args,...)
        if U.run() then
            if args.type=='win' then U.record('wins',1,'win')
            elseif args.type=='ante_up' then U.record('ante',args.ante or 1,nil,true)
            elseif args.type=='modify_jokers' or args.type=='have_edition' then U.jokers() end
        end
        return result
    end
    local unlock=G.FUNCS.unlock_all
    G.FUNCS.unlock_all=function(...) local result=unlock(...);U.profile();return result end
    local start=Game.start_run
    function Game:start_run(args,...)
        U.profile()
        local result=start(self,args,...)
        local s=M.state()
        -- Loading is discovery evidence, never permission to bypass a requirement.
        for id,n in pairs(s and s.levels or {}) do if n>0 then U.discover(id) end end
        U.jokers();U.check();return result
    end
    assert(SMODS.load_file('tracking.lua'))()(U,P)
    local discovered,discover=U.discovered,U.discover
    function U.discovered(id) if expansion_ids[id] then return PortraitExpansion48.discovered(expansion_ids[id]) end;return discovered(id) end
    function U.discover(id) if expansion_ids[id] then return PortraitExpansion48.discover(expansion_ids[id]) end;return discover(id) end
    assert(SMODS.load_file('notifications.lua'))()(U,M)
    return U
end
