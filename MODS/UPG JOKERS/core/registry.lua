return function(mod)
    local R={mod=mod, entries={}, order={}}
    function R.register(def)
        assert(not R.entries[def.key], 'Duplicate UPG Joker: '..def.key)
        R.entries[def.key]=def
        R.order[#R.order+1]=def.key
        if mod.config.jokers[def.key]==nil then mod.config.jokers[def.key]=true end
        if mod.config.upg_weights[def.key]==nil then mod.config.upg_weights[def.key]=1 end
    end
    function R.config()
        return G.GAME and G.GAME.upg_jokers_config or mod.config
    end
    function R.enabled(key)
        local c=R.config()
        return c.enabled==true and c.jokers[key]==true and (c.upg_weights[key] or 0)>0
    end
    function R.is_upg_pool(pool)
        local found=false
        for _,key in ipairs(pool) do
            if key~='UNAVAILABLE' then
                local center=G.P_CENTERS[key]
                if not center or not R.entries[center.upg_id] then return false end
                found=true
            end
        end
        return found
    end
    function R.choose(pool,roll)
        local total=0
        for _,key in ipairs(pool) do
            local id=G.P_CENTERS[key] and G.P_CENTERS[key].upg_id
            if id and R.enabled(id) then total=total+R.config().upg_weights[id] end
        end
        if total<=0 then return end
        local draw=roll*total
        for index,key in ipairs(pool) do
            local id=G.P_CENTERS[key] and G.P_CENTERS[key].upg_id
            if id and R.enabled(id) then
                draw=draw-R.config().upg_weights[id]
                if draw<0 then return key,index end
            end
        end
    end
    function R.pick(pool,seed)
        if R.is_upg_pool(pool) then return R.choose(pool,pseudorandom(seed)) end
        return pseudorandom_element(pool,seed)
    end
    function R.weight(object_type)
        if R.calculating_weight or not G.GAME then return 0 end
        local pool=get_current_pool('Joker','upg_upgraded',false,'upg_weight')
        if not R.is_upg_pool(pool) then return 0 end
        local p=math.max(0,math.min(0.99,R.config().upg_target_probability))
        if p==0 then return 0 end
        R.calculating_weight=true
        local total=0
        object_type=object_type or SMODS.ObjectTypes.Joker
        for _,entry in ipairs(object_type.rarities or {}) do
            if entry.key~='upg_upgraded' then
                local other_pool=get_current_pool('Joker',entry.key,false,'upg_weight')
                if not (#other_pool==1 and other_pool[1]=='empty_rarity') then
                    local rarity=SMODS.Rarities[entry.key]
                    local weight=entry.weight or (rarity and rarity.default_weight) or 0
                    if rarity and rarity.get_weight then weight=rarity:get_weight(weight,object_type) end
                    total=total+math.max(0,(weight or 0)*(G.GAME[tostring(entry.key):lower()..'_mod'] or 1))
                end
            end
        end
        R.calculating_weight=false
        -- w / (other + w) = p. With base weights summing to 1, w = 1/99.
        -- Steamodded still applies the UPG-specific modifier after this hook.
        return total*p/(1-p)
    end
    function R.for_card(card)
        local center=card.config and card.config.center
        return center and R.entries[center.upg_id]
    end
    -- Called immediately after Game:start_run assigns G.GAME, before cards are
    -- generated. This also runs after the existing legacy-save migration.
    function R.begin_run(loading)
        if UPGJokers then UPGJokers.evolution.animation.reset() end
        if not loading or not G.GAME.upg_jokers_config then
            G.GAME.upg_jokers_config=copy_table(mod.config)
            -- Existing runs without a snapshot keep their original pools.
            if loading then G.GAME.upg_jokers_config.enabled=false end
        end
        -- New definitions remain loadable without adding them to an old run's pool.
        local snapshot=G.GAME.upg_jokers_config
        for key,value in pairs(mod.config) do
            if snapshot[key]==nil and key~='jokers' then
                snapshot[key]=type(value)=='table' and copy_table(value) or value
            end
        end
        for _,key in ipairs(R.order) do
            if snapshot.jokers[key]==nil then snapshot.jokers[key]=false end
        end
    end
    return R
end
