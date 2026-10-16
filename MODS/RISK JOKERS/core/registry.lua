return function(mod)
    local R={mod=mod, entries={}, order={}}
    function R.register(def)
        assert(not R.entries[def.key], 'Duplicate RISK Joker: '..def.key)
        R.entries[def.key]=def
        R.order[#R.order+1]=def.key
        if mod.config.jokers[def.key]==nil then mod.config.jokers[def.key]=true end
        if mod.config.risk_weights[def.key]==nil then mod.config.risk_weights[def.key]=1 end
    end
    function R.config()
        return G.GAME and G.GAME.risk_jokers_config or mod.config
    end
    function R.enabled(key)
        local c=R.config()
        return R.entries[key] and R.entries[key].art_available and c.enabled==true and
            c.jokers[key]==true and (c.risk_weights[key] or 0)>0
    end
    function R.is_risk_pool(pool)
        if type(pool)~='table' or not G.P_CENTERS then return false end
        local found=false
        for _,key in ipairs(pool) do
            if key~='UNAVAILABLE' then
                local center=G.P_CENTERS[key]
                if not center or not R.entries[center.risk_id] then return false end
                found=true
            end
        end
        return found
    end
    function R.choose(pool,roll)
        local total=0
        for _,key in ipairs(pool) do
            local id=G.P_CENTERS[key] and G.P_CENTERS[key].risk_id
            if id and R.enabled(id) then total=total+R.config().risk_weights[id] end
        end
        if total<=0 then return end
        local draw=roll*total
        for index,key in ipairs(pool) do
            local id=G.P_CENTERS[key] and G.P_CENTERS[key].risk_id
            if id and R.enabled(id) then
                draw=draw-R.config().risk_weights[id]
                if draw<0 then return key,index end
            end
        end
    end
    function R.weight()
        if not G.GAME then return 0 end
        local pool=get_current_pool('Joker','risk_risk',false,'risk_weight')
        if not R.is_risk_pool(pool) then return 0 end
        return math.max(0,R.config().risk_rarity_weight)
    end
    -- Called immediately after Game:start_run assigns G.GAME, before cards are
    -- generated. This also runs after the existing legacy-save migration.
    function R.begin_run(loading)
        if not loading or not G.GAME.risk_jokers_config then
            G.GAME.risk_jokers_config=copy_table(mod.config)
            -- Existing runs without a snapshot keep their original pools.
            if loading then G.GAME.risk_jokers_config.enabled=false end
        end
        -- New definitions remain loadable without adding them to an old run's pool.
        local snapshot=G.GAME.risk_jokers_config
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
