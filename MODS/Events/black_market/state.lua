return function(R)
    local B={registry=R,active=false,busy=false,areas={'shop_jokers','shop_vouchers','shop_booster'}}
    function B.enabled() return R.enabled('black_market') end
    function B.config()
        local config=R.config()
        if PortraitRunRules and PortraitRunRules.has('black_market') then
            local c={};for k,v in pairs(config) do c[k]=v end
            c.black_market_base_chance=math.min(1,c.black_market_base_chance*2)
            c.black_market_max_chance=math.min(1,c.black_market_max_chance*2)
            return c
        end
        return config
    end
    function B.state()
        local events=G.GAME.portrait_events
        events.black_market=events.black_market or {heat=0,pity=0,cooldown=0,previous=false,serial=0}
        return events.black_market
    end
    function B.current() return B.state().current end
    function B.roll(key)
        return pseudorandom(pseudoseed('evt_bm_'..key))
    end
    function B.choose(list,key)
        if #list==0 then return end
        if RiskJokers and RiskJokers.registry.is_risk_pool(list) then
            return RiskJokers.registry.choose(list,B.roll(key))
        end
        if UPGJokers and UPGJokers.registry.is_upg_pool(list) then
            return UPGJokers.registry.choose(list,B.roll(key))
        end
        return list[math.min(#list,math.floor(B.roll(key)*#list)+1)]
    end
    function B.shop_created()
        if not B.enabled() then return end
        local s,c=B.state(),B.config()
        if s.current then return s.current end
        s.serial=s.serial+1
        local available=false
        if s.previous then s.previous=false
        elseif s.cooldown>0 then s.cooldown=s.cooldown-1
        else
            available=B.roll('access_'..s.serial)<math.min(c.black_market_max_chance,c.black_market_base_chance+s.pity*c.black_market_pity_increment)
            s.pity=available and 0 or s.pity+1
            s.previous=available
        end
        s.current={id=s.serial,available=available,rerolls=0}
        return s.current
    end
    function B.heat_factor()
        local h,c=B.state().heat,B.config()
        return 1+(h>=c.heat_high and c.heat_high_markup or h>=c.heat_medium and c.heat_medium_markup or 0)
    end
    function B.afford(cost) return cost==0 or G.GAME.dollars-G.GAME.bankrupt_at>=cost end
    function B.snapshot()
        local out={}
        for _,name in ipairs(B.areas) do out[name]=copy_table(G[name]:save()) end
        return out
    end
    function B.restore(saved)
        for _,name in ipairs(B.areas) do
            G[name]:load(copy_table(saved[name]))
            for _,card in ipairs(G[name].cards) do card:set_cost(); create_shop_card_ui(card) end
        end
    end
    function B.checkpoint()
        if B.active then B.current().inventory=B.snapshot() end
        save_run()
    end
    function B.reroll_cost()
        if (G.GAME.current_round.free_rerolls or 0)>0 then return 0 end
        local c=B.config()
        local discount=math.max(0,c.normal_reroll_base-(G.GAME.round_resets.reroll_cost or c.normal_reroll_base))
        return math.max(0,c.black_market_reroll_base+B.current().rerolls*c.black_market_reroll_increment-discount)
    end
    return B
end
