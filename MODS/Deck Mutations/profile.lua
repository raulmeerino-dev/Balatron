-- Persistent state belongs to the profile, never the mod toggle or the offer.
return function(U,order,requirements,save)
    local old_requirements={joker_habitat=true,rare_market=true,shiny_market=true,black_market=true,
        frequent_negative=true,large_packs=true,overkill_plus=true,contracts_plus=true,weak_boss=true,
        fewer_commons=true,free_reroll=true,high_stakes=true,double_interest=true,profitable_sale=true,
        free_discard=true,second_pick=true,fortune=true}
    function U.profile()
        local profile=G.PROFILES and G.PROFILES[G.SETTINGS.profile];if not profile then return end
        local data=profile.modifier_unlocks
        local changed=false
        if not data or (data.version or 0)<2 then
            local known=profile.portrait_collection and profile.portrait_collection.mutations or {}
            data=data or {stats={},runs={},serial=0}
            local old=data.unlocked or {}
            data.unlocked={};data.discovered=data.discovered or {};data.best_run=data.best_run or {}
            for _,d in ipairs(order) do
                -- v1 marked every basic rule unlocked without evidence of discovery.
                -- Preserve earned unlocks and actually encountered legacy rules only.
                data.unlocked[d.id]=not requirements[d.id] or old_requirements[d.id] and old[d.id] or known[d.id] and true or nil
                if known[d.id] or old_requirements[d.id] and old[d.id] then data.discovered[d.id]=true end
            end
            for _,stats in pairs(data.runs or {}) do for key,value in pairs(stats) do
                data.best_run[key]=math.max(data.best_run[key] or 0,value)
            end end
            data.evaluate_legacy=next(data.stats or {})~=nil
            data.version=2;profile.modifier_unlocks=data;changed=true
        end
        data.pending_notifications=data.pending_notifications or {}
        data.seen_notifications=data.seen_notifications or {}
        if profile.all_unlocked then
            for _,d in ipairs(order) do
                if not data.unlocked[d.id] or not data.discovered[d.id] or not data.seen_notifications[d.id] then changed=true end
                data.unlocked[d.id]=true;data.discovered[d.id]=true;data.seen_notifications[d.id]=true
            end
            if #data.pending_notifications>0 then data.pending_notifications={};changed=true end
        end
        if changed then save() end
        return data
    end
    function U.discovered(id) local p=U.profile();return p and p.discovered[id] or false end
    function U.discover(id)
        if not U.definitions[id] then return end
        local p=U.profile();if not p or p.discovered[id] then return end
        p.discovered[id]=true;save()
    end
end
